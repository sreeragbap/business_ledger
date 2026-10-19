part of 'sync_cubit.dart';

class SyncState extends Equatable {
  const SyncState({
    this.status = const SyncStatus(),
    this.entries = const [],
    this.actionStatus = const Status.initial(),
  });

  final SyncStatus status;

  /// The signed-in user's outbox, oldest first.
  final List<OutboxEntry> entries;

  /// The last user action (switch, sync now, retry, discard).
  final Status actionStatus;

  List<OutboxEntry> get failed => [
    for (final entry in entries)
      if (entry.isFailed) entry,
  ];

  List<OutboxEntry> get waiting => [
    for (final entry in entries)
      if (!entry.isFailed) entry,
  ];

  SyncState copyWith({
    SyncStatus? status,
    List<OutboxEntry>? entries,
    Status? actionStatus,
  }) => SyncState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    actionStatus: actionStatus ?? this.actionStatus,
  );

  @override
  List<Object?> get props => [status, entries, actionStatus];
}
