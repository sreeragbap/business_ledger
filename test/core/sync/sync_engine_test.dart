import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_executor.dart';
import 'package:business_ledger/core/sync/profile_sync.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_error_policy.dart';
import 'package:business_ledger/core/sync/sync_puller.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';
import 'sync_fakes.dart';

void main() {
  late MemoryOutboxStore outboxStore;
  late Outbox outbox;
  late FakeExecutor executor;
  late FakeConnectivityService connectivity;
  late SyncSettings settings;
  late FakeIdentity identity;
  late FakeRemoteTables remote;
  late LocalStore store;
  late FakeTimers timers;
  late FakeTimers pullTimers;
  late DateTime now;
  SyncEngine? engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    outboxStore = MemoryOutboxStore();
    outbox = Outbox(outboxStore);
    executor = FakeExecutor();
    connectivity = FakeConnectivityService();
    settings = SyncSettings(await SharedPreferences.getInstance());
    identity = FakeIdentity();
    remote = FakeRemoteTables();
    store = memoryStore();
    timers = FakeTimers();
    pullTimers = FakeTimers();
    now = DateTime.utc(2026, 3, 14, 12);
  });

  tearDown(() async {
    await engine?.dispose();
    engine = null;
    await outbox.dispose();
    await connectivity.dispose();
    await identity.dispose();
    await settings.dispose();
    await store.db.close();
  });

  Future<SyncEngine> start(List<OutboxEntry> queued) async {
    outboxStore.saved = List.of(queued);
    final created = SyncEngine(
      outbox,
      executor,
      connectivity,
      settings,
      identity,
      SyncPuller(remote, store),
      store,
      ProfileSync(store, remote),
      now: () => now,
      timer: timers.call,
      pullTimer: pullTimers.call,
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
    expect(remote.calls, isEmpty, reason: 'no pull either');

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

  test('status: pending, failed and local changes for the banner', () async {
    connectivity.online = false;
    final sync = await start([
      entry('a'),
      entry('b', status: OutboxStatus.failed),
      rowWrite('draft', tx: 'd1'),
    ]);
    expect(sync.status.online, isFalse);
    expect(sync.status.pendingCount, 2);
    expect(sync.status.failedCount, 1);
    expect(sync.status.localChanges, 1);
    expect(sync.status.hasLocalChanges, isTrue);
  });

  group('row writes', () {
    test(
      "a draft's upsert replays before the confirm queued after it",
      () async {
        await start([
          rowWrite('draft'),
          entry('confirm', kind: OutboxKind.confirm),
          entry('pay'),
        ]);
        expect(executor.sentIds, ['draft', 'confirm', 'pay']);
      },
    );

    test('a refused draft holds back its confirm; others go on', () async {
      executor.answer('draft', [
        Failure(
          serverError('permission-denied', AppErrorKind.permissionDenied),
        ),
      ]);
      final sync = await start([
        rowWrite('draft'),
        entry('confirm', kind: OutboxKind.confirm),
        entry('elsewhere', tx: 't2'),
      ]);
      expect(executor.sentIds, ['draft', 'elsewhere']);
      expect(stored('draft')!.status, OutboxStatus.failed);
      expect(stored('confirm')!.status, OutboxStatus.pending);
      expect(sync.status.failedCount, 1);
    });

    test('a pushed row is no longer pending locally, unless another queued '
        'write still touches it', () async {
      await store.claimFor('u1');
      await store.writeLocal(SyncTable.categories, {
        'id': 'c1',
        'business_id': 'b1',
        'name': 'Food',
      });
      await store.writeLocal(SyncTable.categories, {
        'id': 'c2',
        'business_id': 'b1',
        'name': 'Fuel',
      });
      executor.answer('second', [
        Failure(serverError('internal', AppErrorKind.unknown)),
      ]);
      await start([
        rowWrite('first', table: 'categories', row: 'c1', tx: null),
        rowWrite('second', table: 'categories', row: 'c2', tx: null),
      ]);
      expect(
        (await store.readRow(SyncTable.categories, {
          'id': 'c1',
        }))!['local_pending'],
        isFalse,
      );
      expect(
        (await store.readRow(SyncTable.categories, {
          'id': 'c2',
        }))!['local_pending'],
        isTrue,
        reason: 'its write is still waiting (backoff)',
      );
    });

    test('end to end: RLS refusing a pushed draft fails the entry and keeps '
        'the local row pending', () async {
      await store.claimFor('u1');
      remote.refuse.add('transactions');
      await store.writeLocal(SyncTable.transactions, {
        'id': 'd1',
        'business_id': 'b1',
        'status': 'draft',
      });
      final rpc = FakeRemoteRpc();
      final availability = CloudAvailability(connectivity, settings, identity);
      final real = SyncEngine(
        outbox,
        SupabaseOutboxExecutor(RpcClient(rpc, availability), remote),
        connectivity,
        settings,
        identity,
        SyncPuller(remote, store),
        store,
        ProfileSync(store, remote),
        now: () => now,
        timer: timers.call,
        pullTimer: pullTimers.call,
      );
      engine = real;
      outboxStore.saved = [
        rowWrite('draft', tx: 'd1'),
        entry('confirm', tx: 'd1', kind: OutboxKind.confirm),
      ];
      await real.start();
      await settle();
      expect(remote.calls, contains('upsert transactions'));
      expect(stored('draft')!.status, OutboxStatus.failed);
      expect(stored('draft')!.lastError!.code, 'permission-denied');
      expect(stored('confirm')!.status, OutboxStatus.pending);
      expect(rpc.calls, isEmpty, reason: 'held back behind its draft');
      final local = await store.readRow(SyncTable.transactions, {'id': 'd1'});
      expect(local!['local_pending'], isTrue);
    });

    test(
      'discarding a row write drops the local row and re-pulls its table',
      () async {
        await store.claimFor('u1');
        executor.answer('draft', [
          Failure(
            serverError('permission-denied', AppErrorKind.permissionDenied),
          ),
        ]);
        await store.writeLocal(SyncTable.transactions, {
          'id': 'd1',
          'business_id': 'b1',
          'status': 'draft',
        });
        await store.setCursor('b1', SyncTable.transactions, 40);
        final sync = await start([rowWrite('draft', tx: 'd1')]);
        await sync.discard('draft');
        await settle();
        expect(
          await store.readRow(SyncTable.transactions, {'id': 'd1'}),
          isNull,
        );
        expect(await store.cursor('b1', SyncTable.transactions), 0);
      },
    );
  });

  group('pull', () {
    test('runs on start and after a push that applied something', () async {
      remote.seed('businesses', {'id': 'b1', 'name': 'Shop'});
      final sync = await start([]);
      expect(remote.calls.where((c) => c == 'select businesses'), hasLength(1));
      expect(sync.status.lastSyncedAt, now);
      expect(await store.businessIds(), ['b1']);

      await outbox.add(entry('pay'));
      await settle();
      expect(executor.sentIds, ['pay']);
      expect(remote.calls.where((c) => c == 'select businesses'), hasLength(2));
    });

    test(
      'runs again on reconnect, on sync switched on and periodically',
      () async {
        await start([]);
        int pulls() =>
            remote.calls.where((c) => c == 'select businesses').length;
        expect(pulls(), 1);

        connectivity.online = false;
        await settle();
        connectivity.online = true;
        await settle();
        expect(pulls(), 2);

        await settings.setEnabled(value: false);
        await settle();
        await settings.setEnabled(value: true);
        await settle();
        expect(pulls(), 3);

        expect(pullTimers.active!.delay, SyncEngine.defaultPullInterval);
        pullTimers.fire();
        await settle();
        expect(pulls(), 4);
      },
    );

    test(
      'pauses the periodic pull in the background; pulls on return',
      () async {
        final sync = await start([]);
        int pulls() =>
            remote.calls.where((c) => c == 'select businesses').length;
        sync.setForeground(foreground: false);
        expect(pullTimers.active, isNull);
        sync.setForeground(foreground: true);
        await settle();
        expect(pulls(), 2);
        expect(pullTimers.active, isNotNull);
      },
    );

    test('refresh (pull-to-refresh) completes with the pull', () async {
      final sync = await start([]);
      remote.seed('businesses', {'id': 'b2', 'name': 'New'});
      final result = await sync.refresh();
      expect(result.isSuccess, isTrue);
      expect(await store.businessIds(), ['b2']);

      connectivity.online = false;
      await settle();
      expect((await sync.refresh()).errorOrNull?.kind, AppErrorKind.offline);
    });

    test('a new user signing in gets a wiped store, then their pull', () async {
      remote.seed('businesses', {'id': 'b1', 'name': 'Shop'});
      await start([]);
      expect(await store.businessIds(), ['b1']);

      remote.memberOf = {};
      identity.current = 'u2';
      await settle();
      expect(await store.businessIds(), isEmpty);
    });
  });
}

int _rowSeq = 0;

/// A queued row write of user `u1`: an upsert of row [row] (default: [tx])
/// of [table] in business `b1`.
OutboxEntry rowWrite(
  String id, {
  String table = 'transactions',
  String? row,
  String? tx = 't1',
}) => OutboxEntry(
  id: id,
  uid: 'u1',
  businessId: 'b1',
  kind: OutboxKind.upsert,
  payload: {
    'table': table,
    'rows': [
      {'id': row ?? tx ?? id, 'business_id': 'b1'},
    ],
  },
  transactionId: tx,
  label: 'Row $id',
  createdAt: DateTime.utc(2026, 3, 14, 8, 0, _rowSeq++ % 60),
);
