import 'dart:async';

import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_executor.dart';
import 'package:business_ledger/core/sync/profile_sync.dart';
import 'package:business_ledger/core/sync/sync_error_policy.dart';
import 'package:business_ledger/core/sync/sync_identity.dart';
import 'package:business_ledger/core/sync/sync_puller.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:business_ledger/core/sync/sync_status.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Schedules `run` after `delay`. Injected so tests can see (and fire)
/// the backoff and pull timers.
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

/// Keeps this device and Supabase in step (ARCHITECTURE §2, Offline
/// behaviour). Runs while a user is signed in, Cloud sync is on and the
/// device is online.
///
/// **Push.** Sends that user's outbox entries oldest first, one at a time:
/// row writes (drafts, configuration, business settings) through PostgREST
/// and money actions through their RPCs. One FIFO queue, so a draft's
/// upsert always lands before the confirm queued after it.
///
/// * success removes the entry, clears the rows' `local_pending` mark (when
///   nothing else is queued for them) and chains the version of later edits
///   to the same transaction;
/// * a definitive refusal marks it failed and holds back later entries for
///   the same transaction (they probably depend on it), not others;
/// * a transient failure keeps it pending with exponential backoff, and a
///   reconnect or "Sync now" retries at once.
///
/// **Pull** (`SyncPuller`): on start, on sign-in, on reconnect or sync
/// switched on, after every push that applied something, on "Sync now" and
/// pull-to-refresh ([refresh]), and every [defaultPullInterval] while the
/// app is in the foreground.
@lazySingleton
class SyncEngine {
  SyncEngine(
    this._outbox,
    this._executor,
    this._connectivity,
    this._settings,
    this._identity,
    this._puller,
    this._store,
    this._profiles, {
    @ignoreParam DateTime Function()? now,
    @ignoreParam SyncTimerFactory? timer,
    @ignoreParam SyncTimerFactory? pullTimer,
    @ignoreParam Duration? pullInterval,
  }) : _now = now ?? DateTime.now,
       _timerFactory = timer ?? Timer.new,
       _pullTimerFactory = pullTimer ?? Timer.new,
       _pullInterval = pullInterval ?? defaultPullInterval;

  final Outbox _outbox;
  final OutboxExecutor _executor;
  final ConnectivityService _connectivity;
  final SyncSettings _settings;
  final SyncIdentity _identity;
  final SyncPuller _puller;
  final LocalStore _store;
  final ProfileSync _profiles;
  final DateTime Function() _now;
  final SyncTimerFactory _timerFactory;
  final SyncTimerFactory _pullTimerFactory;
  final Duration _pullInterval;

  /// How often the foreground app looks for other devices' changes.
  /// (Supabase Realtime could replace this poll later.)
  static const Duration defaultPullInterval = Duration(seconds: 60);

  final BehaviorSubject<SyncStatus> _status =
      BehaviorSubject<SyncStatus>.seeded(const SyncStatus());
  final StreamController<SyncEvent> _events =
      StreamController<SyncEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  bool _started = false;
  String? _uid;
  bool _online = true;
  bool _enabled = true;
  bool _foreground = true;
  DateTime? _lastSyncedAt;

  bool _running = false;
  bool _again = false;
  bool _busy = false;
  bool _pullWanted = false;
  Timer? _timer;
  Timer? _pullTimer;
  final List<Completer<AppResult<void>>> _pullWaiters = [];

  /// The local store is being claimed for a newly signed-in user.
  Future<void> _claimed = Future<void>.value();

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
    final uid = _uid;
    if (uid != null) _claimed = _claim(uid);
    _subscriptions
      ..add(
        _identity.uidChanges.listen((uid) {
          if (uid == _uid) return;
          _uid = uid;
          if (uid != null) _claimed = _claim(uid);
          _pullWanted = uid != null;
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
      );
    _pullWanted = true;
    _emitStatus();
    _kick();
  }

  /// A newly signed-in user's data must never mix with the last one's.
  Future<void> _claim(String uid) async {
    try {
      await _store.claimFor(uid);
    } catch (_) {
      // The store is unusable; the pull will fail and say so.
    }
  }

  void _onAvailability({bool? online, bool? enabled}) {
    final could = _canSend;
    _online = online ?? _online;
    _enabled = enabled ?? _enabled;
    _emitStatus();
    if (!could && _canSend) {
      // Back online / switched on: whatever was backing off goes now, and
      // whatever changed elsewhere meanwhile comes down.
      _pullWanted = true;
      unawaited(_resetBackoff().then((_) => _kick()));
      return;
    }
    _kick();
  }

  /// The app came to the foreground (or left it). Pulls at once on return,
  /// then every interval while it stays.
  void setForeground({required bool foreground}) {
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (foreground) {
      _pullWanted = true;
      _kick();
    } else {
      _pullTimer?.cancel();
      _pullTimer = null;
    }
  }

  // --- User actions ----------------------------------------------------------

  /// Retries everything waiting now, ignoring backoff, then pulls.
  Future<void> syncNow() async {
    await _resetBackoff();
    _pullWanted = true;
    _kick();
  }

  /// Pull-to-refresh: pushes what waits, then pulls. Completes when the
  /// pull has finished (or at once, unavailable, when the engine cannot
  /// reach the server).
  Future<AppResult<void>> refresh() {
    if (!_started || !_canSend) {
      return Future.value(
        Failure(
          _uid == null
              ? CloudAvailability.signedOut
              : _enabled
              ? const AppException.offline()
              : const AppException.syncOff(),
        ),
      );
    }
    final waiter = Completer<AppResult<void>>();
    _pullWaiters.add(waiter);
    _pullWanted = true;
    _kick();
    return waiter.future;
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
  ///
  /// A discarded row write leaves the local row out of step with the
  /// server, so it is dropped and its table pulled again from the start:
  /// the server's version (if any) comes back.
  Future<List<OutboxEntry>> discard(
    String id, {
    bool includeDependents = true,
  }) async {
    final entry = _outbox.byId(id);
    if (entry == null || entry.uid != _uid) return const [];
    final removed = [entry, if (includeDependents) ...dependentsOf(id)];
    await _outbox.remove(removed.map((e) => e.id));
    await _restoreRows(removed);
    _pullWanted = true;
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
    await _restoreRows(mine);
    return mine;
  }

  Future<void> _restoreRows(List<OutboxEntry> removed) async {
    for (final entry in removed) {
      final table = entry.table;
      if (table == null) continue;
      for (final key in entry.rowKeys) {
        try {
          if (table.scoped) {
            await _store.deleteRow(table, key);
            await _store.setCursor(entry.businessId, table, 0);
          } else {
            // Businesses and the profile are re-read whole on every pull.
            await _store.clearPending(table, key);
          }
        } catch (_) {
          // Best effort: the row stays as it is until the next change.
        }
      }
    }
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
      await _claimed;
      do {
        _again = false;
        // The network went down mid-pass: a pull would fail the same way.
        if (await _pass()) break;
        if (_pullWanted && _canSend) await _pull();
      } while (_again && _canSend);
    } finally {
      _running = false;
      _busy = false;
      _scheduleWake();
      _schedulePull();
      _emitStatus();
      // Anyone still waiting asked for a pull that could not run (offline,
      // signed out, or the network failed mid-pass).
      _answerWaiters(_unavailable());
    }
  }

  /// Sends due entries until none is left. `true` means stop for now (the
  /// network is down, or sending is not allowed).
  Future<bool> _pass() async {
    while (_canSend) {
      final entry = _next();
      if (entry == null) return false;
      _busy = true;
      _emitStatus();
      // It may have been discarded meanwhile.
      final current = _outbox.byId(entry.id);
      if (current == null || !current.isPending) continue;
      if (!await _replay(current)) return true;
    }
    return true;
  }

  Future<void> _pull() async {
    final uid = _uid;
    if (uid == null) return;
    _pullWanted = false;
    await _profiles.push(uid);
    final result = await _puller.pull(uid);
    if (result.isSuccess) {
      _lastSyncedAt = _now();
      unawaited(_settings.setLastSyncedAt(_lastSyncedAt!));
    }
    _answerWaiters(result);
  }

  void _answerWaiters(AppResult<void> result) {
    if (_pullWaiters.isEmpty) return;
    final waiters = List.of(_pullWaiters);
    _pullWaiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete(result);
    }
  }

  AppResult<void> _unavailable() => Failure(
    _uid == null
        ? CloudAvailability.signedOut
        : _enabled
        ? const AppException.offline()
        : const AppException.syncOff(),
  );

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
        if (tx != null && !entry.isRowWrite) {
          // The server bumped the version by one: later edits queued
          // against the old version expect one more.
          await _outbox.updateWhere(
            (other) => other.uid == entry.uid && other.transactionId == tx,
            (other) =>
                other.copyWith(chainedSuccesses: other.chainedSuccesses + 1),
          );
        }
        await _settle(entry);
        _pullWanted = true;
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

  /// A pushed row write: its rows no longer wait, unless another queued
  /// entry still writes them.
  Future<void> _settle(OutboxEntry entry) async {
    final table = entry.table;
    if (table == null) return;
    final stillQueued = {
      for (final other in currentEntries)
        if (other.table == table)
          for (final key in other.rowKeys) table.keyText(key),
    };
    for (final key in entry.rowKeys) {
      if (stillQueued.contains(table.keyText(key))) continue;
      try {
        await _store.clearPending(table, key);
      } catch (_) {
        // The next pull of a newer version overwrites it anyway.
      }
    }
  }

  Future<void> _resetBackoff() async {
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
    DateTime? earliest;
    for (final entry in currentEntries) {
      final next = entry.nextAttemptAt;
      if (!entry.isPending || next == null) continue;
      if (earliest == null || next.isBefore(earliest)) earliest = next;
    }
    if (earliest == null) return;
    final delay = earliest.difference(now);
    _timer = _timerFactory(delay.isNegative ? Duration.zero : delay, _kick);
  }

  /// The next periodic pull, while in the foreground.
  void _schedulePull() {
    _pullTimer?.cancel();
    _pullTimer = null;
    if (!_canSend || !_foreground) return;
    _pullTimer = _pullTimerFactory(_pullInterval, () {
      _pullWanted = true;
      _kick();
    });
  }

  void _emit(SyncEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _emitStatus() {
    if (_status.isClosed) return;
    final mine = currentEntries;
    final failed = mine.where((entry) => entry.isFailed).length;
    final local = mine
        .where((entry) => entry.isRowWrite && !entry.isFailed)
        .length;
    _status.add(
      SyncStatus(
        syncEnabled: _enabled,
        online: _online,
        syncing: _busy && _canSend,
        pendingCount: mine.length - failed,
        failedCount: failed,
        localChanges: local,
        lastSyncedAt: _lastSyncedAt,
      ),
    );
  }

  @disposeMethod
  Future<void> dispose() async {
    _timer?.cancel();
    _pullTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _answerWaiters(_unavailable());
    await _status.close();
    await _events.close();
  }
}
