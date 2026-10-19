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
    this.firestoreHasPendingWrites = false,
    this.lastSyncedAt,
  });

  /// The Cloud sync switch.
  final bool syncEnabled;

  /// The device has a network interface up.
  final bool online;

  /// An outbox entry is being sent, or the engine is waiting for local
  /// writes to reach the server first.
  final bool syncing;

  /// Outbox entries waiting (pending or being sent).
  final int pendingCount;

  /// Outbox entries the server refused.
  final int failedCount;

  /// Draft / configuration writes that Firestore has queued but the server
  /// has not acknowledged. A heuristic (Firestore has no "pending count"
  /// API): writes this session handed off without an acknowledgement, plus
  /// a `waitForPendingWrites()` probe at start and on reconnect that has
  /// not completed within a grace period.
  final bool firestoreHasPendingWrites;

  /// When the outbox last applied an entry on the server.
  final DateTime? lastSyncedAt;

  /// The engine is allowed to send.
  bool get canSync => online && syncEnabled;

  /// Nothing to show: online, on, and nothing waiting.
  bool get isIdle =>
      canSync &&
      !syncing &&
      pendingCount == 0 &&
      failedCount == 0 &&
      !firestoreHasPendingWrites;

  SyncStatus copyWith({
    bool? syncEnabled,
    bool? online,
    bool? syncing,
    int? pendingCount,
    int? failedCount,
    bool? firestoreHasPendingWrites,
    DateTime? lastSyncedAt,
  }) => SyncStatus(
    syncEnabled: syncEnabled ?? this.syncEnabled,
    online: online ?? this.online,
    syncing: syncing ?? this.syncing,
    pendingCount: pendingCount ?? this.pendingCount,
    failedCount: failedCount ?? this.failedCount,
    firestoreHasPendingWrites:
        firestoreHasPendingWrites ?? this.firestoreHasPendingWrites,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  @override
  List<Object?> get props => [
    syncEnabled,
    online,
    syncing,
    pendingCount,
    failedCount,
    firestoreHasPendingWrites,
    lastSyncedAt,
  ];
}
