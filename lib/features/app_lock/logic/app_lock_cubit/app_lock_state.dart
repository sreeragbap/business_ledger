part of 'app_lock_cubit.dart';

class AppLockState extends Equatable {
  const AppLockState({
    this.enabled = false,
    this.locked = false,
    this.unlockStatus = const Status.initial(),
    this.toggleStatus = const Status.initial(),
  });

  /// The user's setting.
  final bool enabled;

  /// Whether the lock screen must be showing now.
  final bool locked;

  final Status unlockStatus;

  /// Turning the setting on or off.
  final Status toggleStatus;

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    Status? unlockStatus,
    Status? toggleStatus,
  }) => AppLockState(
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    unlockStatus: unlockStatus ?? this.unlockStatus,
    toggleStatus: toggleStatus ?? this.toggleStatus,
  );

  @override
  List<Object?> get props => [enabled, locked, unlockStatus, toggleStatus];
}
