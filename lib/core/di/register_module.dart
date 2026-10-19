import 'package:business_ledger/app/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Third-party instances that cannot carry an injectable annotation.
///
/// Registered here rather than built inside each service (the reference's
/// `withX` test-constructor pattern) so services take them as plain
/// constructor parameters and tests pass fakes the same way.
@module
abstract class RegisterModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;

  @lazySingleton
  LocalAuthentication get localAuthentication => LocalAuthentication();

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// Resolved during `configureDependencies()` so reads are synchronous.
  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
