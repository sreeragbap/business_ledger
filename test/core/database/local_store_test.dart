import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

void main() {
  late LocalStore store;

  setUp(() async {
    store = memoryStore();
    await store.claimFor('u1');
  });

  tearDown(() => store.db.close());

  Map<String, dynamic> tx(String id, {int seq = 1, String business = 'b1'}) => {
    'id': id,
    'business_id': business,
    'type': 'sale',
    'direction': 'in',
    'status': 'confirmed',
    'date': '2026-10-01',
    'line_items': [
      {
        'description': 'Bags',
        'quantityMilli': 2500,
        'rateMinor': 40000,
        'amountMinor': 100000,
      },
    ],
    'total_minor': 10000000000000,
    'outstanding_minor': 9999999999999,
    'is_open': true,
    'custom_fields': {'f1': 'x'},
    'search_tokens': ['ce', 'cem'],
    'version': 2,
    'created_by': 'u1',
    'created_at': '2026-10-01T05:00:00.123456+00:00',
    'seq': seq,
    'some_future_column': 'ignored',
  };

  group('rows', () {
    test(
      'a Postgres row round-trips: money as int, JSON as maps and lists',
      () async {
        await store.upsertRows(SyncTable.transactions, [tx('t1')]);
        final row = await store.readRow(SyncTable.transactions, {'id': 't1'});
        expect(row!['total_minor'], 10000000000000);
        expect(row['outstanding_minor'], isA<int>());
        expect(row['is_open'], isTrue);
        expect((row['line_items'] as List).single, {
          'description': 'Bags',
          'quantityMilli': 2500,
          'rateMinor': 40000,
          'amountMinor': 100000,
        });
        expect(row['custom_fields'], {'f1': 'x'});
        expect(row['search_tokens'], ['ce', 'cem']);
        expect(row['created_at'], '2026-10-01T05:00:00.123456+00:00');
        expect(row['local_pending'], isFalse);
        expect(row.containsKey('some_future_column'), isFalse);
      },
    );

    test(
      'composite keys: members, settlements, documents, daily stats',
      () async {
        await store.upsertRows(SyncTable.members, [
          {'business_id': 'b1', 'user_id': 'u1', 'role': 'owner'},
          {'business_id': 'b2', 'user_id': 'u1', 'role': 'viewer'},
        ]);
        await store.upsertRows(SyncTable.dailyStats, [
          {
            'business_id': 'b1',
            'date': '2026-10-01',
            'income_minor': 500,
            'by_category': {
              'c1': {'in': 500, 'out': 0},
            },
          },
        ]);
        final member = await store.readRow(SyncTable.members, {
          'business_id': 'b2',
          'user_id': 'u1',
        });
        expect(member!['role'], 'viewer');
        final stats = await store.readRow(SyncTable.dailyStats, {
          'business_id': 'b1',
          'date': '2026-10-01',
        });
        expect(stats!['by_category'], {
          'c1': {'in': 500, 'out': 0},
        });
        await store.deleteRow(SyncTable.members, {
          'business_id': 'b1',
          'user_id': 'u1',
        });
        expect(
          await store.readRow(SyncTable.members, {
            'business_id': 'b1',
            'user_id': 'u1',
          }),
          isNull,
        );
      },
    );

    test(
      'a local write merges over the stored row and is marked pending',
      () async {
        await store.upsertRows(SyncTable.categories, [
          {
            'id': 'c1',
            'business_id': 'b1',
            'name': 'Food',
            'kind': 'expense',
            'seq': 9,
          },
        ]);
        await store.writeLocal(SyncTable.categories, {
          'id': 'c1',
          'name': 'Groceries',
        });
        final row = await store.readRow(SyncTable.categories, {'id': 'c1'});
        expect(row!['name'], 'Groceries');
        expect(row['kind'], 'expense', reason: 'kept');
        expect(row['seq'], 9, reason: 'kept until the server stamps a new one');
        expect(row['local_pending'], isTrue);
        expect(await store.pendingRows(SyncTable.categories), hasLength(1));

        await store.clearPending(SyncTable.categories, {'id': 'c1'});
        expect(await store.pendingRows(SyncTable.categories), isEmpty);
      },
    );

    test('a new local row gets zero values and a creation time', () async {
      await store.writeLocal(SyncTable.parties, {
        'id': 'p1',
        'business_id': 'b1',
        'name': 'Asha',
      });
      final row = await store.readRow(SyncTable.parties, {'id': 'p1'});
      expect(row!['archived'], isFalse);
      expect(row['sort_order'], 0);
      expect(row['created_at'], isNotNull);
    });

    test('patchLocal changes only an existing row', () async {
      await store.patchLocal(SyncTable.projects, {'id': 'x'}, {'name': 'n'});
      expect(await store.readRow(SyncTable.projects, {'id': 'x'}), isNull);
    });
  });

  group('applyPage', () {
    test('upserts, removes tombstones and moves the cursor', () async {
      await store.upsertRows(SyncTable.transactions, [tx('t1'), tx('t2')]);
      await store.applyPage(SyncTable.transactions, 'b1', [
        {...tx('t1', seq: 5), 'description': 'updated'},
        {
          ...tx('t2', seq: 6),
          'status': 'draft',
          'deleted_at': '2026-10-02T00:00:00+00:00',
        },
        tx('t3', seq: 7),
      ], cursor: 7);
      final t1 = await store.readRow(SyncTable.transactions, {'id': 't1'});
      expect(t1!['description'], 'updated');
      expect(await store.readRow(SyncTable.transactions, {'id': 't2'}), isNull);
      expect(
        await store.readRow(SyncTable.transactions, {'id': 't3'}),
        isNotNull,
      );
      expect(await store.cursor('b1', SyncTable.transactions), 7);
      expect(await store.cursor('b2', SyncTable.transactions), 0);
    });

    test('never overwrites a row with a local change waiting', () async {
      await store.writeLocal(SyncTable.transactions, {
        ...tx('t1'),
        'description': 'mine',
      });
      await store.applyPage(SyncTable.transactions, 'b1', [
        {...tx('t1', seq: 8), 'description': 'theirs'},
      ], cursor: 8);
      final row = await store.readRow(SyncTable.transactions, {'id': 't1'});
      expect(row!['description'], 'mine');
      expect(await store.cursor('b1', SyncTable.transactions), 8);
    });
  });

  group('businesses and owner', () {
    test(
      'wipeBusiness removes the business, its rows and cursors only',
      () async {
        await store.upsertRows(SyncTable.businesses, [
          {'id': 'b1', 'name': 'One'},
          {'id': 'b2', 'name': 'Two'},
        ]);
        await store.upsertRows(SyncTable.transactions, [
          tx('t1'),
          tx('t2', business: 'b2'),
        ]);
        await store.setCursor('b1', SyncTable.transactions, 4);
        await store.setCursor('b2', SyncTable.transactions, 5);

        await store.wipeBusiness('b1');
        expect(await store.businessIds(), ['b2']);
        expect(
          await store.readRow(SyncTable.transactions, {'id': 't1'}),
          isNull,
        );
        expect(
          await store.readRow(SyncTable.transactions, {'id': 't2'}),
          isNotNull,
        );
        expect(await store.cursor('b1', SyncTable.transactions), 0);
        expect(await store.cursor('b2', SyncTable.transactions), 5);
      },
    );

    test(
      'claimFor another user wipes everything and forgets the pull',
      () async {
        await store.upsertRows(SyncTable.businesses, [
          {'id': 'b1', 'name': 'One'},
        ]);
        await store.markPulled();
        expect(await store.hasPulled(), isTrue);
        expect(await store.claimFor('u1'), isFalse, reason: 'same user');
        expect(await store.businessIds(), ['b1']);

        expect(await store.claimFor('u2'), isTrue);
        expect(await store.businessIds(), isEmpty);
        expect(await store.hasPulled(), isFalse);
      },
    );

    test('two claims at once for the same new user wipe once', () async {
      await store.claimFor('u0');
      final results = await Future.wait([
        store.claimFor('u2'),
        store.claimFor('u2'),
      ]);
      expect(results, [true, false]);
    });

    test(
      'release (sign-out) wipes everything; any next user starts fresh',
      () async {
        await store.upsertRows(SyncTable.businesses, [
          {'id': 'b1', 'name': 'One'},
        ]);
        await store.markPulled();
        await store.release();
        expect(await store.businessIds(), isEmpty);
        expect(await store.hasPulled(), isFalse);
        expect(await store.claimFor('u1'), isFalse, reason: 'nothing to wipe');
      },
    );

    test('watchPulled emits the current value, then the change', () async {
      final seen = <bool>[];
      final subscription = store.watchPulled().listen(seen.add);
      await pumpEventQueue();
      await store.markPulled();
      await pumpEventQueue();
      expect(seen, [false, true]);
      await subscription.cancel();
    });
  });
}
