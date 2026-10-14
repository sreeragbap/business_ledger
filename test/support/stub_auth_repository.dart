import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/auth/domain/const/social_sign_in_method.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/domain/repository/auth_repository.dart';

/// Hand-written [AuthRepository] for bloc tests. Push users through
/// [emitUser]; set [signInResult] / [signOutResult] before acting.
class StubAuthRepository extends AuthRepository {
  StubAuthRepository({AppUser? initialUser}) : _current = initialUser;

  final StreamController<AppUser?> _users =
      StreamController<AppUser?>.broadcast();
  AppUser? _current;

  AppResult<AppUser> signInResult = const Success(
    AppUser(uid: 'u1', displayName: 'Asha Rao', email: 'asha@example.com'),
  );
  AppResult<void> signOutResult = const Success(null);

  final List<SocialSignInMethod> signInCalls = [];
  int signOutCalls = 0;

  void emitUser(AppUser? user) {
    _current = user;
    _users.add(user);
  }

  @override
  Stream<AppUser?> get userChanges => _users.stream;

  @override
  AppUser? get currentUser => _current;

  @override
  Future<AppResult<AppUser>> signIn(SocialSignInMethod method) async {
    signInCalls.add(method);
    return signInResult;
  }

  @override
  Future<AppResult<void>> signOut() async {
    signOutCalls++;
    return signOutResult;
  }

  Future<void> dispose() => _users.close();
}
