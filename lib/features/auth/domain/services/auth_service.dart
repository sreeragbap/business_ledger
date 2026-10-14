import 'dart:convert';
import 'dart:math';

import 'package:business_ledger/app/app_config.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/crashlytics_service.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/features/auth/domain/const/social_sign_in_method.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/domain/repository/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Concrete [AuthRepository] over Firebase Auth, Google Sign-In (7.x API) and
/// Sign in with Apple.
@LazySingleton(as: AuthRepository)
class AuthService implements AuthRepository {
  AuthService(this._auth, this._google, this._refs, this._crashlytics);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  final FirestoreRefs _refs;
  final CrashlyticsService _crashlytics;

  /// `GoogleSignIn.initialize` must run exactly once per process.
  Future<void>? _googleReady;

  @override
  Stream<AppUser?> get userChanges => _auth.authStateChanges().map(_toUser);

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Future<AppResult<AppUser>> signIn(SocialSignInMethod method) async {
    try {
      final credential = switch (method) {
        SocialSignInMethod.google => await _signInWithGoogle(),
        SocialSignInMethod.apple => await _signInWithApple(),
      };
      final user = credential.user;
      if (user == null) return Failure(AppException.unknown('No user'));

      await _upsertProfile(user);
      await _crashlytics.setUserIdentifier(user.uid);
      return Success(_toUser(_auth.currentUser ?? user)!);
    } on GoogleSignInException catch (error) {
      return Failure(_fromGoogle(error));
    } on SignInWithAppleAuthorizationException catch (error) {
      return Failure(
        error.code == AuthorizationErrorCode.canceled
            ? const AppException.cancelled()
            : const AppException(
                kind: AppErrorKind.unknown,
                message: 'Apple sign-in failed. Please try again.',
              ),
      );
    } on SignInWithAppleNotSupportedException {
      return const Failure(
        AppException(
          kind: AppErrorKind.unknown,
          message: 'Sign in with Apple is not available on this device.',
        ),
      );
    } catch (error, stack) {
      final exception = AppException.from(error);
      if (exception.kind == AppErrorKind.unknown) {
        await _crashlytics.recordError(error, stack, reason: 'Sign-in failed');
      }
      return Failure(exception);
    }
  }

  @override
  Future<AppResult<void>> signOut() => AppResult.guard(() async {
    await _auth.signOut();
    await _crashlytics.clearUserIdentifier();
    try {
      // So the next Google sign-in shows the account picker again.
      await _google.signOut();
    } catch (_) {
      // Not signed in with Google, or the plugin is not initialised.
    }
  });

  // --- Google ----------------------------------------------------------------

  Future<UserCredential> _signInWithGoogle() async {
    await (_googleReady ??= _google.initialize(
      // Android reads its client from google-services.json; iOS needs it
      // passed. flutterfire writes it into the options as `iosClientId`.
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? AppConfig.firebaseOptions.iosClientId
          : null,
    ));

    final account = await _google.authenticate(
      scopeHint: const ['email', 'profile'],
    );
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AppException(
        kind: AppErrorKind.unknown,
        message: 'Google did not return an identity. Please try again.',
      );
    }
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  AppException _fromGoogle(GoogleSignInException error) => switch (error.code) {
    GoogleSignInExceptionCode.canceled => const AppException.cancelled(),
    _ => AppException(
      kind: AppErrorKind.unknown,
      message: 'Google sign-in failed. Please try again.',
      code: error.code.name,
      cause: error.description,
    ),
  };

  // --- Apple -----------------------------------------------------------------

  /// Native Apple flow with a hashed nonce: Apple embeds `sha256(rawNonce)`
  /// in the identity token, Firebase checks it against `rawNonce`, so a
  /// replayed token is useless.
  Future<UserCredential> _signInWithApple() async {
    final rawNonce = _nonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = apple.identityToken;
    if (idToken == null) {
      throw const AppException(
        kind: AppErrorKind.unknown,
        message: 'Apple did not return an identity. Please try again.',
      );
    }

    final credential = await _auth.signInWithCredential(
      AppleAuthProvider.credentialWithIDToken(
        idToken,
        rawNonce,
        AppleFullPersonName(
          givenName: apple.givenName,
          familyName: apple.familyName,
        ),
      ),
    );

    // Apple sends the name only on the very first authorisation, and
    // Firebase does not copy it onto the user. Keep it while we have it.
    final user = credential.user;
    final name = [
      apple.givenName,
      apple.familyName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    if (user != null &&
        (user.displayName?.isEmpty ?? true) &&
        name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }
    return credential;
  }

  static String _nonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // --- Profile ---------------------------------------------------------------

  /// Creates `users/{uid}` on first sign-in and refreshes the display fields
  /// on every later one. `createdAt` is written once.
  ///
  /// Best effort: a profile write that fails (rules, a flaky network) must
  /// not undo a successful sign-in. The next sign-in retries it.
  Future<void> _upsertProfile(User user) async {
    final ref = _refs.user(user.uid);
    try {
      final snapshot = await ref.get();
      await ref.set(<String, dynamic>{
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error, stack) {
      await _crashlytics.recordError(
        error,
        stack,
        reason: 'Could not write users/{uid}',
      );
    }
  }

  static AppUser? _toUser(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoURL,
        );
}
