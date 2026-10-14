import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_auth_repository.dart';

const _user = AppUser(uid: 'u1', displayName: 'Asha Rao');

void main() {
  late StubAuthRepository repository;

  setUp(() => repository = StubAuthRepository());
  tearDown(() => repository.dispose());

  test('starts from the current user', () {
    expect(
      AuthCubit(StubAuthRepository(initialUser: _user)).state,
      const AuthState(status: AuthStatus.authenticated, user: _user),
    );
    expect(
      AuthCubit(repository).state.status,
      AuthStatus.unauthenticated,
    );
  });

  blocTest<AuthCubit, AuthState>(
    'follows the user stream',
    build: () => AuthCubit(repository),
    act: (_) => repository
      ..emitUser(_user)
      ..emitUser(null),
    expect: () => const [
      AuthState(status: AuthStatus.authenticated, user: _user),
      AuthState(status: AuthStatus.unauthenticated),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'sign out reports loading then success',
    build: () => AuthCubit(StubAuthRepository(initialUser: _user)),
    act: (cubit) => cubit.signOut(),
    expect: () => const [
      AuthState(
        status: AuthStatus.authenticated,
        user: _user,
        signOutStatus: Status.loading(),
      ),
      AuthState(
        status: AuthStatus.authenticated,
        user: _user,
        signOutStatus: Status.success(),
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'sign out failure carries the message',
    build: () {
      repository.signOutResult = const Failure(AppException.offline());
      return AuthCubit(repository);
    },
    act: (cubit) => cubit.signOut(),
    skip: 1,
    expect: () => [
      AuthState(
        status: AuthStatus.unauthenticated,
        signOutStatus: Status.fromException(const AppException.offline()),
      ),
    ],
  );
}
