import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/auth/domain/const/social_sign_in_method.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/logic/sign_in_cubit/sign_in_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_auth_repository.dart';

const _user = AppUser(uid: 'u1', email: 'asha@example.com');

void main() {
  late StubAuthRepository repository;

  setUp(() => repository = StubAuthRepository());
  tearDown(() => repository.dispose());

  blocTest<SignInCubit, SignInState>(
    'loading for the chosen provider, then success with the user',
    build: () {
      repository.signInResult = const Success(_user);
      return SignInCubit(repository);
    },
    act: (cubit) => cubit.signIn(SocialSignInMethod.google),
    expect: () => const [
      SignInState(status: Status.loading(), method: SocialSignInMethod.google),
      SignInState(
        status: Status.success(),
        method: SocialSignInMethod.google,
        user: _user,
      ),
    ],
    verify: (cubit) {
      expect(repository.signInCalls, [SocialSignInMethod.google]);
      expect(cubit.state.isLoading(SocialSignInMethod.google), isFalse);
    },
  );

  blocTest<SignInCubit, SignInState>(
    'a dismissed sheet returns to rest without an error',
    build: () {
      repository.signInResult = const Failure(AppException.cancelled());
      return SignInCubit(repository);
    },
    act: (cubit) => cubit.signIn(SocialSignInMethod.apple),
    expect: () => const [
      SignInState(status: Status.loading(), method: SocialSignInMethod.apple),
      SignInState(),
    ],
  );

  blocTest<SignInCubit, SignInState>(
    'a real failure carries a user-safe message',
    build: () {
      repository.signInResult = const Failure(AppException.offline());
      return SignInCubit(repository);
    },
    act: (cubit) => cubit.signIn(SocialSignInMethod.google),
    skip: 1,
    expect: () => [
      SignInState(
        status: Status.fromException(const AppException.offline()),
        method: SocialSignInMethod.google,
      ),
    ],
    verify: (cubit) => expect(cubit.state.status.message, contains('offline')),
  );

  blocTest<SignInCubit, SignInState>(
    'ignores a second tap while a sheet is open',
    build: () => SignInCubit(repository),
    seed: () => const SignInState(
      status: Status.loading(),
      method: SocialSignInMethod.google,
    ),
    act: (cubit) => cubit.signIn(SocialSignInMethod.apple),
    expect: () => const <SignInState>[],
    verify: (_) => expect(repository.signInCalls, isEmpty),
  );

  test('only the chosen provider shows loading', () {
    const state = SignInState(
      status: Status.loading(),
      method: SocialSignInMethod.apple,
    );
    expect(state.isLoading(SocialSignInMethod.apple), isTrue);
    expect(state.isLoading(SocialSignInMethod.google), isFalse);
  });
}
