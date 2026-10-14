import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/app_lock/domain/repository/app_lock_repository.dart';
import 'package:business_ledger/features/app_lock/logic/app_lock_cubit/app_lock_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAppLockRepository extends AppLockRepository {
  _StubAppLockRepository({this.enabled = false});

  bool enabled;
  bool supported = true;
  AppResult<void> authResult = const Success(null);
  int authCalls = 0;

  @override
  bool get isEnabled => enabled;

  @override
  Future<AppResult<void>> setEnabled({required bool enabled}) async {
    this.enabled = enabled;
    return const Success(null);
  }

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<AppResult<void>> authenticate({required String reason}) async {
    authCalls++;
    return authResult;
  }
}

void main() {
  final t0 = DateTime(2026);

  group('locking', () {
    blocTest<AppLockCubit, AppLockState>(
      'cold start locks when enabled',
      build: () => AppLockCubit(_StubAppLockRepository(enabled: true)),
      act: (cubit) => cubit.lockOnColdStart(),
      expect: () => const [AppLockState(enabled: true, locked: true)],
    );

    blocTest<AppLockCubit, AppLockState>(
      'cold start does nothing when disabled',
      build: () => AppLockCubit(_StubAppLockRepository()),
      act: (cubit) => cubit.lockOnColdStart(),
      expect: () => const <AppLockState>[],
    );

    blocTest<AppLockCubit, AppLockState>(
      'locks after 60s in the background',
      build: () => AppLockCubit(_StubAppLockRepository(enabled: true)),
      act: (cubit) => cubit
        ..onBackgrounded(t0)
        ..onResumed(t0.add(AppLockCubit.backgroundTimeout)),
      expect: () => const [AppLockState(enabled: true, locked: true)],
    );

    blocTest<AppLockCubit, AppLockState>(
      'a short trip to the background does not lock',
      build: () => AppLockCubit(_StubAppLockRepository(enabled: true)),
      act: (cubit) => cubit
        ..onBackgrounded(t0)
        ..onResumed(t0.add(const Duration(seconds: 59))),
      expect: () => const <AppLockState>[],
    );
  });

  group('unlocking', () {
    blocTest<AppLockCubit, AppLockState>(
      'success unlocks',
      build: () => AppLockCubit(_StubAppLockRepository(enabled: true)),
      seed: () => const AppLockState(enabled: true, locked: true),
      act: (cubit) => cubit.unlock(),
      expect: () => const [
        AppLockState(
          enabled: true,
          locked: true,
          unlockStatus: Status.loading(),
        ),
        AppLockState(enabled: true, unlockStatus: Status.success()),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'a dismissed prompt stays locked, quietly',
      build: () => AppLockCubit(
        _StubAppLockRepository(enabled: true)
          ..authResult = const Failure(AppException.cancelled()),
      ),
      seed: () => const AppLockState(enabled: true, locked: true),
      act: (cubit) => cubit.unlock(),
      skip: 1,
      expect: () => const [AppLockState(enabled: true, locked: true)],
    );
  });

  group('setting', () {
    blocTest<AppLockCubit, AppLockState>(
      'turning on asks for authentication, then saves',
      build: () => AppLockCubit(_StubAppLockRepository()),
      act: (cubit) => cubit.setEnabled(enabled: true),
      expect: () => const [
        AppLockState(toggleStatus: Status.loading()),
        AppLockState(enabled: true, toggleStatus: Status.success()),
      ],
    );

    blocTest<AppLockCubit, AppLockState>(
      'unsupported device cannot turn it on',
      build: () => AppLockCubit(_StubAppLockRepository()..supported = false),
      act: (cubit) => cubit.setEnabled(enabled: true),
      skip: 1,
      verify: (cubit) {
        expect(cubit.state.enabled, isFalse);
        expect(cubit.state.toggleStatus.isFailure, isTrue);
      },
    );
  });
}
