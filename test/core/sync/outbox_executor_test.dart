import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_executor.dart';
import 'package:business_ledger/core/sync/sync_error_policy.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';
import 'sync_fakes.dart';

/// How each outbox entry is replayed against Supabase.
void main() {
  late FakeRemoteRpc rpc;
  late FakeRemoteTables tables;
  late SupabaseOutboxExecutor executor;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    rpc = FakeRemoteRpc();
    tables = FakeRemoteTables();
    final availability = CloudAvailability(
      FakeConnectivityService(isOnline: false),
      SyncSettings(await SharedPreferences.getInstance()),
      FakeIdentity(),
    );
    executor = SupabaseOutboxExecutor(RpcClient(rpc, availability), tables);
  });

  OutboxEntry rows(String id, String table, List<Map<String, Object?>> rows) =>
      OutboxEntry(
        id: id,
        uid: 'u1',
        businessId: 'b1',
        kind: OutboxKind.upsert,
        payload: {'table': table, 'rows': rows},
        label: id,
        createdAt: DateTime.utc(2026),
      );

  OutboxEntry updates(String id, String table, List<RowUpdate> updates) =>
      OutboxEntry(
        id: id,
        uid: 'u1',
        businessId: 'b1',
        kind: OutboxKind.update,
        payload: {
          'table': table,
          'updates': [for (final update in updates) update.toJson()],
        },
        label: id,
        createdAt: DateTime.utc(2026),
      );

  test('a money action replays its RPC with the chained payload, even '
      'though the up-front check would say offline', () async {
    final edit = entry(
      'edit',
      kind: OutboxKind.edit,
      baseVersion: 2,
      payload: {
        'expectedVersion': 2,
        'changes': {'description': 'x'},
      },
    ).copyWith(chainedSuccesses: 1);
    final result = await executor.run(edit);
    expect(result.isSuccess, isTrue);
    expect(rpc.calls.single.$1, 'edit_confirmed_transaction');
    expect(rpc.calls.single.$2['p_expected_version'], 3);
    expect(rpc.calls.single.$2['p_changes'], {'description': 'x'});
  });

  test('an upsert sends the rows to their table', () async {
    final result = await executor.run(
      rows('u', 'categories', [
        {'id': 'c1', 'business_id': 'b1', 'name': 'Food'},
      ]),
    );
    expect(result.isSuccess, isTrue);
    expect(tables.rows('categories').single['name'], 'Food');
  });

  test('an update sets the columns on each matched row', () async {
    tables
      ..seed('categories', {'id': 'c1', 'sort_order': 0})
      ..seed('categories', {'id': 'c2', 'sort_order': 1});
    final result = await executor.run(
      updates('reorder', 'categories', const [
        RowUpdate({'id': 'c1'}, {'sort_order': 1}),
        RowUpdate({'id': 'c2'}, {'sort_order': 0}),
      ]),
    );
    expect(result.isSuccess, isTrue);
    expect(
      [for (final row in tables.rows('categories')) row['sort_order']],
      [
        1,
        0,
      ],
    );
  });

  test('row level security refusing an upsert (42501) is a definitive '
      'permission failure', () async {
    tables.refuse.add('transactions');
    final result = await executor.run(
      rows('draft', 'transactions', [
        {'id': 't1', 'business_id': 'b1'},
      ]),
    );
    final error = result.errorOrNull!;
    expect(error.kind, AppErrorKind.permissionDenied);
    expect(SyncErrorPolicy.isTransient(error), isFalse);
  });

  test('an update that changes no row (RLS, or the row moved on) fails '
      'definitively', () async {
    final result = await executor.run(
      updates('edit', 'transactions', const [
        RowUpdate({'id': 'gone'}, {'description': 'x'}),
      ]),
    );
    expect(result.errorOrNull, SupabaseOutboxExecutor.updateRefused);
    expect(SyncErrorPolicy.isTransient(result.errorOrNull!), isFalse);
  });

  test('row writes round-trip through the outbox file format', () {
    final entry = updates('e', 'parties', const [
      RowUpdate({'id': 'p1'}, {'archived': true}),
    ]);
    final read = OutboxEntry.fromJson(entry.toJson());
    expect(read, entry);
    expect(read.table?.name, 'parties');
    expect(read.updates.single.values, {'archived': true});
    expect(read.rowKeys, [
      {'id': 'p1'},
    ]);
    expect(read.isRowWrite, isTrue);
  });
}
