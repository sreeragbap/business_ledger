import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:equatable/equatable.dart';

/// What happened to an action that may be queued: the server applied it
/// ([Applied]), or it waits in the outbox ([Queued]) and will be applied
/// (or refused) when synced.
sealed class ActionOutcome<T> extends Equatable {
  const ActionOutcome();

  const factory ActionOutcome.applied(T result) = Applied<T>;

  const factory ActionOutcome.queued(OutboxEntry entry) = Queued<T>;

  bool get isQueued => this is Queued<T>;

  /// The server's result, when applied.
  T? get resultOrNull => switch (this) {
    Applied<T>(:final result) => result,
    Queued<T>() => null,
  };

  ActionOutcome<R> map<R>(R Function(T result) transform) => switch (this) {
    Applied<T>(:final result) => Applied<R>(transform(result)),
    Queued<T>(:final entry) => Queued<R>(entry),
  };
}

final class Applied<T> extends ActionOutcome<T> {
  const Applied(this.result);

  final T result;

  @override
  List<Object?> get props => [result];
}

final class Queued<T> extends ActionOutcome<T> {
  const Queued(this.entry);

  final OutboxEntry entry;

  @override
  List<Object?> get props => [entry];
}
