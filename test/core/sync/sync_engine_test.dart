import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/pending_writes_tracker.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_error_policy.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_fakes.dart';

void main() {
  late MemoryOutboxStore store;
  late Outbox outbox;
  late FakeExecutor executor;
  late FakeNetwork network;
  late FakeConnectivityService connectivity;
  late SyncSettings settings;
  late FakeIdentity identity;
  late PendingWritesTracker writes;
  late FakeTimers timers;
  late DateTime now;
  SyncEngine? engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = MemoryOutboxStore();
    outbox = Outbox(store);
    executor = FakeExecutor();
    network = FakeNetwork();
    connectivity = FakeConnectivityService();
    settings = SyncSettings(await SharedPreferences.getInstance(), network);
    identity = FakeIdentity();
    writes = PendingWritesTracker();
    timers = FakeTimers();
    now = DateTime.utc(2026, 3, 14, 12);
  });

  tearDown(() async {
    await engine?.dispose();
    engine = null;
    await outbox.dispose();
    await connectivity.dispose();
    await identity.dispose();
    await writes.dispose();
    await settings.dispose();
  });

  Future<SyncEngine> start(
    List<OutboxEntry> queued, {
    Duration writesTimeout = const Duration(milliseconds: 20),
  }) async {
    store.saved = List.of(queued);
    final created = SyncEngine(
      outbox,
      executor,
      network,
      connectivity,
      settings,
      identity,
      writes,
      now: () => now,
      timer: timers.call,
      pendingWritesTimeout: writesTimeout,
      probeGrace: const Duration(milliseconds: 5),
    );
    engine = created;
    await created.start();
    await settle();
    return created;
  }

  OutboxEntry? stored(String id) => outbox.byId(id);

  const violation = AppException(
    kind: AppErrorKind.violation,
    code: 'failed-precondition',
    message: 'That payment is more than what is outstanding.',
  );

  test('replays oldest first, one at a time, and empties the queue', () async {
    final sync = await start([
      entry('a'),
      entry('b', tx: 't2'),
      entry('c', kind: OutboxKind.cancel),
    ]);
    expect(executor.sentIds, ['a', 'b', 'c']);
    expect(outbox.entries, isEmpty);
    expect(sync.status.pendingCount, 0);
    expect(sync.status.lastSyncedAt, now);
    expect(settings.lastSyncedAt, isNotNull);
  });

  test('stale expectedVersion is dropped where optional; edits are chained '
      'by the earlier successes on the same transaction', () async {
    await start([
      entry('pay', payload: {'expectedVersion': 3, 'amountMinor': 100}),
      entry(
        'edit1',
        kind: OutboxKind.edit,
        baseVersion: 3,
        payload: {'expectedVersion': 3},
      ),
      entry('other', tx: 't2', kind: OutboxKind.edit, baseVersion: 9),
      entry(
        'edit2',
        kind: OutboxKind.edit,
        baseVersion: 3,
        payload: {'expectedVersion': 3},
      ),
    ]);
    final byId = {for (final e in executor.sent) e.id: e.replayPayload};
    expect(byId['pay']!.containsKey('expectedVersion'), isFalse);
    expect(byId['pay']!['amountMinor'], 100);
    expect(byId['edit1']!['expectedVersion'], 4, reason: 'after the payment');
    expect(byId['other']!['expectedVersion'], 9, reason: 'other transaction');
    expect(byId['edit2']!['expectedVersion'], 5, reason: 'payment + edit1');
  });

  test('a definitive refusal fails the entry, holds back later entries of the '
      'same transaction, and lets others through', () async {
    executor.answer('pay', [const Failure(violation)]);
    final events = <SyncEvent>[];
    final sync = await start([
      entry('pay'),
      entry('edit', kind: OutboxKind.edit, baseVersion: 2),
      entry('elsewhere', tx: 't2'),
    ]);
    sync.events.listen(events.add);
    expect(executor.sentIds, ['pay', 'elsewhere']);
    expect(stored('pay')!.status, OutboxStatus.failed);
    expect(stored('pay')!.lastError!.message, violation.message);
    expect(stored('pay')!.lastError!.code, 'failed-precondition');
    expect(stored('edit')!.status, OutboxStatus.pending);
    expect(sync.status.failedCount, 1);
    expect(sync.status.pendingCount, 1);

    // Retry with the same requestId: it goes, then its dependent, chained.
    await sync.retry('pay');
    await settle();
    expect(executor.sentIds, ['pay', 'elsewhere', 'pay', 'edit']);
    expect(executor.sent[2].payload['requestId'], 'pay');
    expect(executor.sent.last.replayPayload['expectedVersion'], 3);
    expect(outbox.entries, isEmpty);
    expect(events.where((e) => e.type == SyncEventType.applied), hasLength(2));
  });

  test('a conflict on replay says someone else changed it', () async {
    executor.answer('edit', [
      const Failure(
        AppException(
          kind: AppErrorKind.conflict,
          code: 'aborted',
          message: 'This record was changed by someone else.',
        ),
      ),
    ]);
    await start([entry('edit', kind: OutboxKind.edit, baseVersion: 1)]);
    expect(stored('edit')!.status, OutboxStatus.failed);
    expect(stored('edit')!.lastError!.message, SyncErrorPolicy.conflictMessage);
  });

  group('error classification', () {
    final cases = <AppException, bool>{
      serverError('unavailable', AppErrorKind.offline): true,
      serverError('deadline-exceeded', AppErrorKind.timeout): true,
      serverError('internal', AppErrorKind.unknown): true,
      serverError('resource-exhausted', AppErrorKind.unknown): true,
      const AppException.offline(): true,
      serverError('invalid-argument', AppErrorKind.validation): false,
      serverError('failed-precondition', AppErrorKind.violation): false,
      serverError('permission-denied', AppErrorKind.permissionDenied): false,
      serverError('not-found', AppErrorKind.notFound): false,
      serverError('already-exists', AppErrorKind.requestReused): false,
      serverError('aborted', AppErrorKind.conflict): false,
      serverError('unauthenticated', AppErrorKind.unauthenticated): false,
    };
    for (final MapEntry(key: error, value: transient) in cases.entries) {
      test('${error.code ?? error.kind.name} is '
          '${transient ? 'transient' : 'definitive'}', () {
        expect(SyncErrorPolicy.isTransient(error), transient);
      });
    }
  });

  test('a transient failure keeps the entry pending with exponential backoff '
      'and holds its transaction meanwhile', () async {
    executor.answer('pay', [
      Failure(serverError('internal', AppErrorKind.unknown)),
      Failure(serverError('internal', AppErrorKind.unknown)),
    ]);
    final sync = await start([
      entry('pay'),
      entry('cancel', kind: OutboxKind.cancel),
      entry('elsewhere', tx: 't2'),
    ]);
    expect(executor.sentIds, ['pay', 'elsewhere']);
    final first = stored('pay')!;
    expect(first.status, OutboxStatus.pending);
    expect(first.attempts, 1);
    expect(first.lastError!.code, 'internal');
    expect(first.nextAttemptAt, now.add(const Duration(seconds: 5)));
    expect(timers.active!.delay, const Duration(seconds: 5));
    expect(sync.status.pendingCount, 2);

    now = now.add(const Duration(seconds: 5));
    timers.fire();
    await settle();
    expect(stored('pay')!.attempts, 2);
    expect(stored('pay')!.nextAttemptAt, now.add(const Duration(seconds: 10)));
    expect(timers.active!.delay, const Duration(seconds: 10));

    now = now.add(const Duration(seconds: 10));
    timers.fire();
    await settle();
    expect(executor.sentIds, ['pay', 'elsewhere', 'pay', 'pay', 'cancel']);
    expect(outbox.entries, isEmpty);
  });

  test('backoff doubles from 5 s and stops at 5 min', () {
    expect(SyncErrorPolicy.backoff(1), const Duration(seconds: 5));
    expect(SyncErrorPolicy.backoff(2), const Duration(seconds: 10));
    expect(SyncErrorPolicy.backoff(4), const Duration(seconds: 40));
    expect(SyncErrorPolicy.backoff(7), const Duration(minutes: 5));
    expect(SyncErrorPolicy.backoff(50), const Duration(minutes: 5));
  });

  test(
    'the network failing stops the pass; reconnecting retries at once',
    () async {
      executor.answer('a', [const Failure(AppException.offline())]);
      await start([entry('a'), entry('b', tx: 't2')]);
      expect(executor.sentIds, ['a'], reason: 'b would fail the same way');

      connectivity.online = false;
      await settle();
      connectivity.online = true;
      await settle();
      expect(executor.sentIds, ['a', 'a', 'b']);
      expect(outbox.entries, isEmpty);
    },
  );

  test('"Sync now" ignores the backoff', () async {
    executor.answer('a', [
      Failure(serverError('unavailable', AppErrorKind.offline)),
    ]);
    final sync = await start([entry('a')]);
    expect(stored('a')!.nextAttemptAt, isNotNull);
    await sync.syncNow();
    await settle();
    expect(executor.sentIds, ['a', 'a']);
    expect(outbox.entries, isEmpty);
  });

  test('nothing is sent while offline or with sync off', () async {
    connectivity.online = false;
    final sync = await start([entry('a')]);
    expect(executor.sent, isEmpty);
    expect(sync.status.online, isFalse);
    expect(sync.status.pendingCount, 1);

    await settings.setEnabled(value: false);
    connectivity.online = true;
    await settle();
    expect(executor.sent, isEmpty, reason: 'sync is off');
    expect(sync.status.syncEnabled, isFalse);
    expect(network.disables, 1);

    await settings.setEnabled(value: true);
    await settle();
    expect(executor.sentIds, ['a']);
  });

  test("only the signed-in user's entries are replayed or counted", () async {
    final sync = await start([
      entry('mine'),
      entry('theirs', uid: 'u2'),
    ]);
    expect(executor.sentIds, ['mine']);
    expect(stored('theirs'), isNotNull, reason: 'kept dormant');
    expect(sync.status.pendingCount, 0);
    expect(sync.currentEntries, isEmpty);

    identity.current = null;
    await settle();
    expect(executor.sentIds, ['mine']);

    identity.current = 'u2';
    await settle();
    expect(executor.sentIds, ['mine', 'theirs']);
  });

  test('waits for local Firestore writes first; a timeout sends nothing and '
      'retries later', () async {
    network.pendingWrites = Completer<void>();
    final sync = await start([entry('confirm', kind: OutboxKind.confirm)]);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await settle();
    expect(executor.sent, isEmpty);
    expect(sync.status.firestoreHasPendingWrites, isTrue);
    expect(stored('confirm')!.attempts, 0, reason: 'not an attempt');
    expect(timers.active!.delay, const Duration(seconds: 5));

    network.pendingWrites!.complete();
    now = now.add(const Duration(seconds: 5));
    timers.fire();
    await settle();
    expect(executor.sentIds, ['confirm']);
    expect(sync.status.firestoreHasPendingWrites, isFalse);
  });

  test('discard removes the entry and, after it, its dependents', () async {
    executor.answer('pay', [const Failure(violation)]);
    final sync = await start([
      entry('pay'),
      entry('edit', kind: OutboxKind.edit, baseVersion: 1),
      entry('elsewhere', tx: 't2'),
    ]);
    expect(sync.dependentsOf('pay').map((e) => e.id), ['edit']);
    final removed = await sync.discard('pay');
    await settle();
    expect(removed.map((e) => e.id), ['pay', 'edit']);
    expect(executor.sentIds, ['pay', 'elsewhere']);
    expect(outbox.entries, isEmpty);
  });

  test('status: pending, failed and local writes for the banner', () async {
    connectivity.online = false;
    final sync = await start([
      entry('a'),
      entry('b', status: OutboxStatus.failed),
    ]);
    writes.begin();
    await settle();
    expect(sync.status.online, isFalse);
    expect(sync.status.pendingCount, 1);
    expect(sync.status.failedCount, 1);
    expect(sync.status.firestoreHasPendingWrites, isTrue);
    writes.end();
    await settle();
    expect(sync.status.firestoreHasPendingWrites, isFalse);
  });
}
