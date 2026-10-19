import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/firestore_network.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_identity.dart';
import 'package:injectable/injectable.dart';

/// A money action that may wait in the outbox.
class QueueableCall {
  const QueueableCall({
    required this.kind,
    required this.businessId,
    required this.transactionId,
    required this.payload,
    required this.label,
    this.baseVersion,
  });

  final OutboxKind kind;
  final String businessId;
  final String transactionId;

  /// The callable input, `requestId` included.
  final Map<String, Object?> payload;
  final String label;

  /// For an edit: the version the user edited.
  final int? baseVersion;

  String get requestId => payload['requestId']! as String;
}

/// The front door for actions that may be queued: sends now when it can,
/// otherwise (offline, sync off, or a transient failure) puts the action in
/// the outbox and answers [Queued]. The sync engine does the rest.
@lazySingleton
class SyncQueue {
  SyncQueue(
    this._callable,
    this._outbox,
    this._availability,
    this._network,
    this._identity, {
    @ignoreParam DateTime Function()? now,
    @ignoreParam Duration? localWritesWait,
  }) : _now = now ?? DateTime.now,
       _localWritesWait = localWritesWait ?? const Duration(seconds: 5);

  final CallableClient _callable;
  final Outbox _outbox;
  final CloudAvailability _availability;
  final FirestoreNetwork _network;
  final SyncIdentity _identity;
  final DateTime Function() _now;
  final Duration _localWritesWait;

  static const AppException signedOut = AppException(
    kind: AppErrorKind.unauthenticated,
    message: 'Your session has ended. Sign in again.',
  );

  /// Runs [call] now, or queues it.
  ///
  /// Queued rather than sent when: the cloud is unavailable; an earlier
  /// action for the same transaction is still queued (order matters); local
  /// Firestore writes are not on the server within a few seconds (the
  /// callable may read them); or the call fails in a way that may be the
  /// network (offline, timeout). The queued entry keeps the requestId, so a
  /// timed-out call that did land is not applied twice.
  Future<AppResult<ActionOutcome<Map<String, dynamic>>>> run(
    QueueableCall call,
  ) async {
    final uid = _identity.uid;
    if (uid == null) return const Failure(signedOut);
    final queued = _outbox.byId(call.requestId);
    if (queued != null) return Success(Queued(queued));

    if (!await _availability.refresh()) return _enqueue(uid, call);
    await _outbox.load();
    final waiting = _outbox.entries.any(
      (entry) => entry.uid == uid && entry.transactionId == call.transactionId,
    );
    if (waiting) return _enqueue(uid, call);
    try {
      await _network.waitForPendingWrites().timeout(_localWritesWait);
    } catch (_) {
      return _enqueue(uid, call);
    }

    final result = await _callable.call(
      call.kind.callable,
      call.payload,
      requiresOnline: false,
    );
    switch (result) {
      case Success(:final data):
        return Success(Applied(data));
      case Failure(:final error):
        if (_mayBeNetwork(error)) return _enqueue(uid, call);
        return Failure(error);
    }
  }

  /// Unavailable, deadline-exceeded, no network: the outcome is unknown or
  /// the server was never reached. Queueing replays it with the same id.
  static bool _mayBeNetwork(AppException error) =>
      error.kind == AppErrorKind.offline || error.kind == AppErrorKind.timeout;

  Future<AppResult<ActionOutcome<Map<String, dynamic>>>> _enqueue(
    String uid,
    QueueableCall call,
  ) => AppResult.guard(() async {
    final entry = OutboxEntry(
      id: call.requestId,
      uid: uid,
      businessId: call.businessId,
      kind: call.kind,
      payload: call.payload,
      transactionId: call.transactionId,
      label: call.label,
      createdAt: _now(),
      baseVersion: call.baseVersion,
    );
    await _outbox.add(entry);
    return Queued<Map<String, dynamic>>(_outbox.byId(entry.id) ?? entry);
  });
}
