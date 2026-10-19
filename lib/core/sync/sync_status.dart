import 'package:equatable/equatable.dart';

/// Everything the sync banner and the Sync screen show, for the signed-in
/// user.
class SyncStatus extends Equatable {
  const SyncStatus({
    this.syncEnabled = true,
    this.online = true,
    this.syncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.localChanges = 0,
    this.lastSyncedAt,
  });

  /// The Cloud sync switch.
  final bool syncEnabled;

  /// The device has a network interface up.
  final bool online;

  /// An outbox entry is being sent.
  final bool syncing;

  /// Outbox entries waiting (pending or being sent): money actions and
  /// local row writes.
  final int pendingCount;

  /// Outbox entries the server refused.
  final int failedCount;

  /// Of [pendingCount], the drafts and settings written on this device and
  /// not uploaded yet (exact: each is an outbox entry).
  final int localChanges;

  /// When this device last finished a push or pull with the server.
  final DateTime? lastSyncedAt;

  /// The engine is allowed to send.
  bool get canSync => online && syncEnabled;

  /// Drafts or settings saved on this device wait to be uploaded.
  bool get hasLocalChanges => localChanges > 0;

  /// Nothing to show: online, on, and nothing waiting.
  bool get isIdle =>
      canSync &&
      !syncing &&
      pendingCount == 0 &&
      failedCount == 0 &&
      !hasLocalChanges;

  SyncStatus copyWith({
    bool? syncEnabled,
    bool? online,
    bool? syncing,
    int? pendingCount,
    int? failedCount,
    int? localChanges,
    DateTime? lastSyncedAt,
  }) => SyncStatus(
    syncEnabled: syncEnabled ?? this.syncEnabled,
    online: online ?? this.online,
    syncing: syncing ?? this.syncing,
    pendingCount: pendingCount ?? this.pendingCount,
    failedCount: failedCount ?? this.failedCount,
    localChanges: localChanges ?? this.localChanges,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  @override
  List<Object?> get props => [
    syncEnabled,
    online,
    syncing,
    pendingCount,
    failedCount,
    localChanges,
    lastSyncedAt,
  ];
}
