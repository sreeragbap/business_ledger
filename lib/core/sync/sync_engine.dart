import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/sync/firestore_network.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_executor.dart';
import 'package:business_ledger/core/sync/pending_writes_tracker.dart';
import 'package:business_ledger/core/sync/sync_error_policy.dart';
import 'package:business_ledger/core/sync/sync_identity.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:business_ledger/core/sync/sync_status.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Schedules `run` after `delay`. Injected so tests can see (and fire)
/// the backoff timers.
typedef SyncTimerFactory = Timer Function(Duration delay, void Function() run);

enum SyncEventType { applied, failed }

/// One entry leaving the queue for good (applied) or stopping (refused).
class SyncEvent extends Equatable {
  const SyncEvent(this.type, this.entry, [this.error]);

  final SyncEventType type;
  final OutboxEntry entry;
  final AppException? error;

  @override
  List<Object?> get props => [type, entry, error];
}

/// Replays the outbox (ARCHITECTURE §2, Offline behaviour).
///
/// Runs while a user is signed in, Cloud sync is on and the device is
/// online; sends that user's entries oldest first, one at a time:
///
/// * before each, waits (with a timeout) for Firestore's own queued writes,
///   so a draft saved offline is on the server before its confirm reads it;
/// * success removes the entry and chains the version of later edits to
///   the same transaction;
/// * a definitive refusal marks it failed and holds back later entries for
///   the same transaction (they probably depend on it), not others;
/// * a transient failure keeps it pending with exponential backoff, and a
///   reconnect or "Sync now" retries at once.
@lazySingleton
class SyncEngine {
  SyncEngine(
    this._outbox,
    this._executor,
    this._network,
    this._connectivity,
    this._settings,
    this._identity,
    this._writes, {
    @ignoreParam DateTime Function()? now,
    @ignoreParam SyncTimerFactory? timer,
    @ignoreParam Duration? pendingWritesTimeout,
    @ignoreParam Duration? probeGrace,
  }) : _now = now ?? DateTime.now,
       _timerFactory = timer ?? Timer.new,
       _pendingWritesTimeout = pendingWritesTimeout ?? defaultWritesTimeout,
       _probeGrace = probeGrace ?? const Duration(seconds: 2);

  final Outbox _outbox;
  final OutboxExecutor _executor;
  final FirestoreNetwork _network;
  final ConnectivityService _connectivity;
  final SyncSettings _settings;
  final SyncIdentity _identity;
  final PendingWritesTracker _writes;
  final DateTime Function() _now;
  final SyncTimerFactory _timerFactory;
  final Duration _pendingWritesTimeout;
  final Duration _probeGrace;

  /// How long a replay waits for local Firestore writes to reach the server.
  static const Duration defaultWritesTimeout = Duration(seconds: 20);

  final BehaviorSubject<SyncStatus> _status =
      BehaviorSubject<SyncStatus>.seeded(const SyncStatus());
  final StreamController<SyncEvent> _events =
      StreamController<SyncEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  bool _started = false;
  String? _uid;
  bool _online = true;
  bool _enabled = true;
  DateTime? _lastSyncedAt;

  bool _running = false;
  bool _again = false;
  bool _busy = false;
  Timer? _timer;

  /// Waiting for Firestore's queue timed out; retry not before this.
  DateTime? _writesRetryAt;
  int _writesFailures = 0;
  bool _probing = false;
  bool _probeOutstanding = false;

  SyncStatus get status => _status.value;

  /// The current status first, then each change.
  Stream<SyncStatus> get statusChanges => _status.stream.distinct();

  Stream<SyncEvent> get events => _events.stream;

  /// The signed-in user's entries, oldest first: the current list first,
  /// then each change.
  Stream<List<OutboxEntry>> get entries =>
      Rx.combineLatest2<List<OutboxEntry>, String?, List<OutboxEntry>>(
        _outbox.changes,
        _identity.uidChanges,
        _ownedBy,
      );

  List<OutboxEntry> get currentEntries => _ownedBy(_outbox.entries, _uid);

  static List<OutboxEntry> _ownedBy(List<OutboxEntry> all, String? uid) =>
      uid == null
      ? const []
      : List.unmodifiable(all.where((entry) => entry.uid == uid));

  bool get _canSend => _uid != null && _online && _enabled;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _uid = _identity.uid;
    _online = _connectivity.isOnline;
    _enabled = _settings.enabled;
    _lastSyncedAt = _settings.lastSyncedAt;
    await _outbox.load();
    _subscriptions
      ..add(
        _identity.uidChanges.listen((uid) {
          if (uid == _uid) return;
          _uid = uid;
          _emitStatus();
          _kick();
        }),
      )
      ..add(
        _connectivity.onlineChanges.listen(
          (online) => _onAvailability(online: online),
        ),
      )
      ..add(
        _settings.enabledChanges.listen(
          (enabled) => _onAvailability(enabled: enabled),
        ),
      )
      ..add(
        _outbox.changes.listen((_) {
          _emitStatus();
          _kick();
        }),
      )
      ..add(_writes.changes.listen((_) => _emitStatus()));
    _emitStatus();
    _probe();
    _kick();
  }

  void _onAvailability({bool? online, bool? enabled}) {
    final could = _canSend;
    _online = online ?? _online;
    _enabled = enabled ?? _enabled;
    _emitStatus();
    if (!could && _canSend) {
      // Back online / switched on: whatever was backing off goes now.
      _probe();
      unawaited(_resetBackoff().then((_) => _kick()));
      return;
    }
    _kick();
  }

  // --- User actions ----------------------------------------------------------

  /// Retries everything waiting now, ignoring backoff.
  Future<void> syncNow() async {
    _probe();
    await _resetBackoff();
    _kick();
  }

  /// Puts a failed entry back in the queue, with the same requestId.
  Future<void> retry(String id) async {
    await _outbox.updateWhere(
      (entry) => entry.id == id && entry.uid == _uid && !entry.isSyncing,
      (entry) => entry.copyWith(
        status: OutboxStatus.pending,
        nextAttemptAt: () => null,
      ),
    );
    _kick();
  }

  /// Later entries for the same transaction, which probably depend on [id].
  List<OutboxEntry> dependentsOf(String id) {
    final mine = currentEntries;
    final index = mine.indexWhere((entry) => entry.id == id);
    if (index < 0) return const [];
    final entry = mine[index];
    if (entry.transactionId == null) return const [];
    return [
      for (final later in mine.skip(index + 1))
        if (later.transactionId == entry.transactionId) later,
    ];
  }

  /// Drops [id] (and, with [includeDependents], [dependentsOf] it) from the
  /// queue without sending. Returns what was removed.
  Future<List<OutboxEntry>> discard(
    String id, {
    bool includeDependents = true,
  }) async {
    final entry = _outbox.byId(id);
    if (entry == null || entry.uid != _uid) return const [];
    final removed = [entry, if (includeDependents) ...dependentsOf(id)];
    await _outbox.remove(removed.map((e) => e.id));
    _kick();
    return removed;
  }

  /// Drops every entry of the signed-in user, for
  /// "Discard and sign out". Returns what was removed. An entry already
  /// being sent may still land: its requestId makes that harmless.
  Future<List<OutboxEntry>> discardAll() async {
    final mine = currentEntries;
    if (mine.isEmpty) return const [];
    await _outbox.remove(mine.map((entry) => entry.id));
    return mine;
  }

  // --- The loop --------------------------------------------------------------

  void _kick() {
    if (!_started) return;
    if (_running) {
      _again = true;
      return;
    }
    unawaited(_drain());
  }

  Future<void> _drain() async {
    _running = true;
    try {
      do {
        _again = false;
        final stop = await _pass();
        if (stop) break;
      } while (_again && _canSend);
    } finally {
      _running = false;
      _busy = false;
      _scheduleWake();
      _emitStatus();
    }
  }

  /// Sends due entries until none is left. `true` means stop for now (the
  /// network is down or local writes are stuck).
  Future<bool> _pass() async {
    while (_canSend) {
      final retryAt = _writesRetryAt;
      if (retryAt != null && retryAt.isAfter(_now())) return true;
      final entry = _next();
      if (entry == null) return false;
      _busy = true;
      _emitStatus();
      if (!await _awaitLocalWrites()) return true;
      if (!_canSend) return true;
      // It may have been discarded while waiting.
      final current = _outbox.byId(entry.id);
      if (current == null || !current.isPending) continue;
      if (!await _replay(current)) return true;
    }
    return true;
  }

  /// The oldest due entry of the signed-in user whose transaction is not
  /// held back by an earlier entry (failed, or still waiting).
  OutboxEntry? _next() {
    final now = _now();
    final held = <String>{};
    for (final entry in currentEntries) {
      final due =
          entry.isPending &&
          (entry.nextAttemptAt == null || !entry.nextAttemptAt!.isAfter(now));
      final tx = entry.transactionId;
      if (tx != null && held.contains(tx)) continue;
      if (due) return entry;
      if (tx != null) held.add(tx);
    }
    return null;
  }

  Future<bool> _awaitLocalWrites() async {
    try {
      await _network.waitForPendingWrites().timeout(_pendingWritesTimeout);
      _writesFailures = 0;
      _writesRetryAt = null;
      return true;
    } catch (_) {
      // Timed out (or the SDK refused): local writes are not on the server
      // yet, so nothing that may read them is sent. Try again later.
      _writesFailures++;
      _writesRetryAt = _now().add(SyncErrorPolicy.backoff(_writesFailures));
      return false;
    }
  }

  /// Sends one entry. `false` stops the pass.
  Future<bool> _replay(OutboxEntry entry) async {
    final sending = entry.copyWith(
      status: OutboxStatus.syncing,
      attempts: entry.attempts + 1,
      nextAttemptAt: () => null,
    );
    await _outbox.update(sending);
    final result = await _executor.run(sending);
    final current = _outbox.byId(entry.id);
    if (current == null) return true; // Discarded while in flight.

    switch (result) {
      case Success():
        await _outbox.remove([entry.id]);
        final tx = entry.transactionId;
        if (tx != null) {
          // The server bumped the version by one: later edits queued
          // against the old version expect one more.
          await _outbox.updateWhere(
            (other) => other.uid == entry.uid && other.transactionId == tx,
            (other) =>
                other.copyWith(chainedSuccesses: other.chainedSuccesses + 1),
          );
        }
        _lastSyncedAt = _now();
        unawaited(_settings.setLastSyncedAt(_lastSyncedAt!));
        _emit(SyncEvent(SyncEventType.applied, entry));
        return true;
      case Failure(:final error):
        if (SyncErrorPolicy.isTransient(error)) {
          await _outbox.update(
            current.copyWith(
              status: OutboxStatus.pending,
              lastError: () => OutboxError.from(error),
              nextAttemptAt: () =>
                  _now().add(SyncErrorPolicy.backoff(sending.attempts)),
            ),
          );
          return !SyncErrorPolicy.isNetworkDown(error);
        }
        final failed = current.copyWith(
          status: OutboxStatus.failed,
          lastError: () => OutboxError(
            message: SyncErrorPolicy.messageFor(error),
            code: error.code ?? error.kind.name,
            violation: error.violation?.name,
          ),
          nextAttemptAt: () => null,
        );
        await _outbox.update(failed);
        _emit(SyncEvent(SyncEventType.failed, failed, error));
        return true;
    }
  }

  Future<void> _resetBackoff() async {
    _writesRetryAt = null;
    await _outbox.updateWhere(
      (entry) =>
          entry.uid == _uid && entry.isPending && entry.nextAttemptAt != null,
      (entry) => entry.copyWith(nextAttemptAt: () => null),
    );
  }

  /// One timer for the earliest backoff to end.
  void _scheduleWake() {
    _timer?.cancel();
    _timer = null;
    if (!_canSend) return;
    final now = _now();
    var earliest = _writesRetryAt;
    for (final entry in currentEntries) {
      final next = entry.nextAttemptAt;
      if (!entry.isPending || next == null) continue;
      if (earliest == null || next.isBefore(earliest)) earliest = next;
    }
    if (earliest == null) return;
    final delay = earliest.difference(now);
    _timer = _timerFactory(delay.isNegative ? Duration.zero : delay, _kick);
  }

  /// Asks Firestore whether it still holds unacknowledged writes (from an
  /// earlier session, say). Not finishing within the grace period counts as
  /// "yes" until it does.
  void _probe() {
    if (_probing) return;
    _probing = true;
    var done = false;
    final grace = Timer(_probeGrace, () {
      if (done) return;
      _probeOutstanding = true;
      _emitStatus();
    });
    unawaited(
      _network
          .waitForPendingWrites()
          .then<void>((_) {}, onError: (Object _) {})
          .whenComplete(() {
            done = true;
            grace.cancel();
            _probing = false;
            _probeOutstanding = false;
            _emitStatus();
          }),
    );
  }

  void _emit(SyncEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _emitStatus() {
    if (_status.isClosed) return;
    final mine = currentEntries;
    final failed = mine.where((entry) => entry.isFailed).length;
    _status.add(
      SyncStatus(
        syncEnabled: _enabled,
        online: _online,
        syncing: _busy && _canSend,
        pendingCount: mine.length - failed,
        failedCount: failed,
        firestoreHasPendingWrites:
            _writes.hasPending || _probeOutstanding || _writesRetryAt != null,
        lastSyncedAt: _lastSyncedAt,
      ),
    );
  }

  @disposeMethod
  Future<void> dispose() async {
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _status.close();
    await _events.close();
  }
}
