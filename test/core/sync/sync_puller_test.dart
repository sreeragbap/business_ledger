import 'dart:io';

import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/sync/sync_puller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_backend.dart';

void main() {
  late FakeRemoteTables remote;
  late LocalStore store;
  late SyncPuller puller;

  setUp(() async {
    remote = FakeRemoteTables();
    store = memoryStore();
    await store.claimFor('u1');
    puller = SyncPuller(remote, store);
    remote
      ..seed('businesses', {'id': 'b1', 'name': 'Shop'})
      ..seed('members', {
        'business_id': 'b1',
        'user_id': 'u1',
        'role': 'editor',
      });
  });

  tearDown(() => store.db.close());

  Future<List<String>> localIds(SyncTable table) async => [
    for (final row
        in await store.db
            .customSelect('SELECT id FROM ${table.name} ORDER BY id')
            .get())
      row.read<String>('id'),
  ];

  test(
    'pulls the profile, businesses and every table; moves cursors',
    () async {
      remote
        ..seed('profiles', {'id': 'u1', 'last_business_id': 'b1'})
        ..seed('profiles', {'id': 'someone-else'})
        ..seed('categories', {'id': 'c1', 'business_id': 'b1', 'name': 'Food'})
        ..seed('transactions', {
          'id': 't1',
          'business_id': 'b1',
          'status': 'confirmed',
          'total_minor': 500,
        });
      expect((await puller.pull('u1')).isSuccess, isTrue);

      expect(await store.businessIds(), ['b1']);
      expect(await localIds(SyncTable.categories), ['c1']);
      expect(await localIds(SyncTable.transactions), ['t1']);
      expect(await localIds(SyncTable.profiles), ['u1']);
      final categorySeq = remote.rows('categories').single['seq'] as int;
      expect(await store.cursor('b1', SyncTable.categories), categorySeq);
      expect(await store.hasPulled(), isTrue);

      // The next pull asks only for what is newer.
      remote.calls.clear();
      await puller.pull('u1');
      expect(
        remote.calls,
        contains('changes categories b1 >$categorySeq #500'),
      );
    },
  );

  test('pages through more than one page, in seq order', () async {
    for (var i = 0; i < 1203; i++) {
      remote.seed('transactions', {
        'id': 't${i.toString().padLeft(4, '0')}',
        'business_id': 'b1',
        'status': 'draft',
      });
    }
    await puller.pull('u1');
    expect(await localIds(SyncTable.transactions), hasLength(1203));
    final pages = remote.calls.where(
      (call) => call.startsWith('changes transactions b1'),
    );
    expect(pages, hasLength(3), reason: '500 + 500 + 203');
    final lastSeq = remote.rows('transactions').last['seq'] as int;
    expect(await store.cursor('b1', SyncTable.transactions), lastSeq);
  });

  test('a soft-deleted row (tombstone) disappears locally', () async {
    remote.seed('transactions', {
      'id': 't1',
      'business_id': 'b1',
      'status': 'draft',
    });
    await puller.pull('u1');
    expect(await localIds(SyncTable.transactions), ['t1']);

    await remote.update(
      'transactions',
      {'id': 't1'},
      {'deleted_at': '2026-10-02T00:00:00+00:00'},
    );
    await puller.pull('u1');
    expect(await localIds(SyncTable.transactions), isEmpty);
  });

  test('a business no longer returned is wiped with all its data', () async {
    remote
      ..seed('businesses', {'id': 'b2', 'name': 'Other'})
      ..seed('categories', {'id': 'c2', 'business_id': 'b2', 'name': 'x'})
      ..seed('categories', {'id': 'c1', 'business_id': 'b1', 'name': 'y'});
    await puller.pull('u1');
    expect(await store.businessIds(), unorderedEquals(['b1', 'b2']));

    remote.memberOf = {'b1'}; // removed from b2
    await puller.pull('u1');
    expect(await store.businessIds(), ['b1']);
    expect(await localIds(SyncTable.categories), ['c1']);
    expect(await store.cursor('b2', SyncTable.categories), 0);
  });

  test('a row changed on this device is not overwritten', () async {
    remote.seed('categories', {'id': 'c1', 'business_id': 'b1', 'name': 'A'});
    await puller.pull('u1');
    await store.writeLocal(SyncTable.categories, {'id': 'c1', 'name': 'Mine'});
    await remote.update('categories', {'id': 'c1'}, {'name': 'Theirs'});
    await puller.pull('u1');
    final row = await store.readRow(SyncTable.categories, {'id': 'c1'});
    expect(row!['name'], 'Mine');
  });

  test(
    'the audit log is pulled for admins only, and dropped on demotion',
    () async {
      remote.seed('audit_log', {
        'id': 1,
        'business_id': 'b1',
        'entity': 'transaction',
        'entity_id': 't1',
        'action': 'confirm',
      });
      await puller.pull('u1');
      expect(
        remote.calls.where((call) => call.startsWith('changes audit_log')),
        isEmpty,
        reason: 'editor',
      );

      await remote.update(
        'members',
        {'business_id': 'b1', 'user_id': 'u1'},
        {'role': 'admin'},
      );
      await puller.pull('u1');
      expect(
        await store.readRow(SyncTable.auditLog, {'id': 1}),
        isNotNull,
      );

      await remote.update(
        'members',
        {'business_id': 'b1', 'user_id': 'u1'},
        {'role': 'viewer'},
      );
      await puller.pull('u1');
      expect(await store.readRow(SyncTable.auditLog, {'id': 1}), isNull);
      expect(await store.cursor('b1', SyncTable.auditLog), 0);
    },
  );

  test('offline: a failure, and the store keeps what it had', () async {
    await puller.pull('u1');
    remote.failNext = const SocketException('down');
    final result = await puller.pull('u1');
    expect(result.errorOrNull?.kind, AppErrorKind.offline);
    expect(await store.businessIds(), ['b1']);
  });

  test('pulls asked for while one runs share the next run', () async {
    final first = puller.pull('u1');
    final second = puller.pull('u1');
    final third = puller.pull('u1');
    await Future.wait([first, second, third]);
    expect(
      remote.calls.where((call) => call == 'select businesses'),
      hasLength(2),
      reason: 'one running, one more for the two that asked meanwhile',
    );
  });
}
