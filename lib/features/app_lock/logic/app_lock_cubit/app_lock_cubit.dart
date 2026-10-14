import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/constants/app_strings.dart';
import 'package:business_ledger/features/app_lock/domain/repository/app_lock_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'app_lock_state.dart';

/// Whether the app is locked, and the rules for locking it.
///
/// Locks on a cold start and after [backgroundTimeout] in the background,
/// when the user has turned the lock on. `App` feeds it lifecycle events and
/// shows the lock screen while [AppLockState.locked].
@lazySingleton
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(this._repository)
    : super(AppLockState(enabled: _repository.isEnabled));

  final AppLockRepository _repository;

  /// How long the app may sit in the background before it locks again.
  static const Duration backgroundTimeout = Duration(seconds: 60);

  DateTime? _backgroundedAt;

  /// Called once per launch, after a signed-in session is known.
  void lockOnColdStart() {
    if (state.enabled) emit(state.copyWith(locked: true));
  }

  /// The app went to the background (or was covered by the system prompt).
  void onBackgrounded([DateTime? at]) {
    // The biometric prompt itself backgrounds the app on some devices;
    // that must not count as leaving it.
    if (state.unlockStatus.isLoading || state.toggleStatus.isLoading) return;
    _backgroundedAt ??= at ?? DateTime.now();
  }

  void onResumed([DateTime? at]) {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (!state.enabled || state.locked || since == null) return;
    if ((at ?? DateTime.now()).difference(since) >= backgroundTimeout) {
      emit(state.copyWith(locked: true, unlockStatus: const Status.initial()));
    }
  }

  Future<void> unlock() async {
    if (!state.locked || state.unlockStatus.isLoading) return;
    emit(state.copyWith(unlockStatus: const Status.loading()));
    final result = await _repository.authenticate(
      reason: AppStrings.unlockReason,
    );
    result.when(
      success: (_) => emit(
        state.copyWith(locked: false, unlockStatus: const Status.success()),
      ),
      failure: (error) => emit(
        state.copyWith(
          unlockStatus: error.isCancelled
              ? const Status.initial()
              : Status.fromException(error),
        ),
      ),
    );
  }

  /// Turning the lock on or off asks for the user's biometrics first: it
  /// proves the prompt works on this device, and stops someone holding an
  /// unlocked phone from switching the lock off.
  Future<void> setEnabled({required bool enabled}) async {
    if (enabled == state.enabled || state.toggleStatus.isLoading) return;
    emit(state.copyWith(toggleStatus: const Status.loading()));

    if (enabled && !await _repository.isSupported()) {
      emit(
        state.copyWith(
          toggleStatus: const Status.failure(
            'Set up a screen lock on this device to use app lock.',
          ),
        ),
      );
      return;
    }

    final auth = await _repository.authenticate(
      reason: AppStrings.enableLockReason,
    );
    if (auth.errorOrNull case final error?) {
      emit(
        state.copyWith(
          toggleStatus: error.isCancelled
              ? const Status.initial()
              : Status.fromException(error),
        ),
      );
      return;
    }

    final saved = await _repository.setEnabled(enabled: enabled);
    saved.when(
      success: (_) => emit(
        state.copyWith(enabled: enabled, toggleStatus: const Status.success()),
      ),
      failure: (error) =>
          emit(state.copyWith(toggleStatus: Status.fromException(error))),
    );
  }

  /// On sign-out: nothing left to protect.
  void reset() {
    _backgroundedAt = null;
    emit(AppLockState(enabled: state.enabled));
  }
}
