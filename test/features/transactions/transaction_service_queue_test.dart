import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_queue.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/domain/services/transaction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/sync/sync_fakes.dart';
import '../../support/fake_backend.dart';

class _Engine extends Mock implements SyncEngine {}

/// The repository's money and draft paths over the real `SyncQueue`,
/// `LocalWriter` and `RpcClient` (with the backend faked): direct when the
/// cloud is reachable, queued in the outbox otherwise.
void main() {
  late FakeRemoteRpc rpc;
  late FakeRemoteTables tables;
  late FakeConnectivityService device;
  late FakeIdentity identity;
  late SyncSettings settings;
  late Outbox outbox;
  late LocalStore store;
  late FakePuller puller;
  late TransactionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    rpc = FakeRemoteRpc();
    tables = FakeRemoteTables();
    device = FakeConnectivityService();
    identity = FakeIdentity();
    settings = SyncSettings(await SharedPreferences.getInstance());
    final availability = CloudAvailability(device, settings, identity);
    outbox = Outbox(MemoryOutboxStore());
    store = memoryStore();
    await store.claimFor('u1');
    puller = FakePuller();
    final queue = SyncQueue(
      RpcClient(rpc, availability),
      outbox,
      availability,
      identity,
      puller,
      now: () => DateTime.utc(2026, 3, 14, 9),
    );
    service = TransactionService(
      store,
      LocalWriter(
        store,
        outbox,
        identity,
        tables,
        availability,
        now: () => DateTime.utc(2026, 3, 14, 9),
      ),
      identity,
      queue,
      _Engine(),
    );
    rpc.answer(
      'record_settlement',
      () => {
        'settlementId': 'r-1',
        'transactionId': 't1',
        'version': 4,
        'paymentStatus': 'paid',
        'outstandingMinor': 0,
      },
    );
  });

  tearDown(() async {
    await outbox.dispose();
    await device.dispose();
    await identity.dispose();
    await store.db.close();
  });

  List<String> calledFunctions() => [for (final call in rpc.calls) call.$1];

  Future<AppResult<ActionOutcome<SettlementResult>>> pay({
    String requestId = 'r-1',
    String transactionId = 't1',
  }) => service.recordSettlement(
    'b1',
    transactionId,
    requestId: requestId,
    kind: SettlementKind.payment,
    amountMinor: 120000,
    date: '2026-03-14',
    method: 'UPI',
    expectedVersion: 3,
    label: 'Payment ₹1,200.00 · Cement bags',
  );

  test('online with sync on: calls the RPC directly, pulls, and returns '
      'the result', () async {
    final result = await pay();
    final outcome = result.dataOrNull!;
    expect(outcome, isA<Applied<SettlementResult>>());
    expect(outcome.resultOrNull!.version, 4);
    expect(calledFunctions(), ['record_settlement']);
    expect(rpc.calls.single.$2, {
      'p_business_id': 'b1',
      'p_transaction_id': 't1',
      'p_request_id': 'r-1',
      'p_kind': 'payment',
      'p_amount_minor': 120000,
      'p_date': '2026-03-14',
      'p_method': 'UPI',
      'p_expected_version': 3,
    });
    expect(puller.pulls, 1, reason: 'the new balance comes down first');
    expect(outbox.entries, isEmpty);
  });

  test(
    'offline: queued with the requestId, label and payload; no call',
    () async {
      device.online = false;
      final result = await pay();
      final entry = (result.dataOrNull! as Queued<SettlementResult>).entry;
      expect(rpc.calls, isEmpty);
      expect(entry.id, 'r-1');
      expect(entry.uid, 'u1');
      expect(entry.kind, OutboxKind.settle);
      expect(entry.callable, 'recordSettlement');
      expect(entry.label, 'Payment ₹1,200.00 · Cement bags');
      expect(entry.payload['amountMinor'], 120000);
      expect(entry.replayPayload.containsKey('expectedVersion'), isFalse);
      expect(outbox.entries.single, entry);
    },
  );

  test('sync off: queued even though the device is online', () async {
    await settings.setEnabled(value: false);
    final result = await pay();
    expect(result.dataOrNull!.isQueued, isTrue);
    expect(rpc.calls, isEmpty);
  });

  test('signed out: refused, nothing queued', () async {
    identity.current = null;
    final result = await pay();
    expect(result.errorOrNull!.kind, AppErrorKind.unauthenticated);
    expect(outbox.entries, isEmpty);
  });

  test('an edit keeps the version it was made against for chaining', () async {
    device.online = false;
    final result = await service.editConfirmed(
      'b1',
      't1',
      requestId: 'r-edit',
      expectedVersion: 7,
      changes: const {'description': 'Cement'},
    );
    final entry = (result.dataOrNull! as Queued<MutationResult>).entry;
    expect(entry.baseVersion, 7);
    expect(entry.replayPayload['expectedVersion'], 7);
    expect(entry.label, 'Edit');
  });

  test(
    'a network failure on the direct call is queued with the same id',
    () async {
      rpc.answers.clear();
      rpc.answer(
        'record_settlement',
        () =>
            throw const PostgrestException(message: 'Bad gateway', code: '503'),
      );
      final result = await pay();
      expect(rpc.calls, hasLength(1));
      expect(result.dataOrNull!.isQueued, isTrue);
      expect(outbox.entries.single.id, 'r-1');
    },
  );

  test('a definitive refusal is returned, not queued', () async {
    rpc.answers.clear();
    rpc.answer(
      'record_settlement',
      () => throw const PostgrestException(
        message: 'That is more than the outstanding balance.',
        code: 'PT412',
        details:
            '{"code": "failed-precondition", "reason": "violation", '
            '"violation": "overpayment"}',
      ),
    );
    final result = await pay();
    expect(result.errorOrNull!.kind, AppErrorKind.violation);
    expect(outbox.entries, isEmpty);
    expect(puller.pulls, 0);
  });

  test('with anything of this user still queued, a new action queues '
      'behind it even online (one FIFO queue)', () async {
    device.online = false;
    await pay();
    device.online = true;
    final second = await pay(requestId: 'r-2');
    expect(second.dataOrNull!.isQueued, isTrue);
    final other = await pay(requestId: 'r-3', transactionId: 't2');
    expect(other.dataOrNull!.isQueued, isTrue);
    expect(rpc.calls, isEmpty);
  });

  test(
    "a refused entry of another transaction doesn't hold new ones back",
    () async {
      await outbox.add(
        entry('old', tx: 't9').copyWith(status: OutboxStatus.failed),
      );
      final result = await pay();
      expect(result.dataOrNull!.isQueued, isFalse);
    },
  );

  group('drafts', () {
    const draft = TransactionDraft(
      id: '7f6c1e9a-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      date: '2026-03-14',
      totalMinor: 5000,
      description: 'Diesel',
    );

    test('saved offline: stored locally (pending) and queued as an upsert; '
        'the confirm queues behind it', () async {
      device.online = false;
      final saved = await service.createDraft('b1', draft);
      expect(saved.isSuccess, isTrue);
      final local = await store.readRow(SyncTable.transactions, {
        'id': draft.id,
      });
      expect(local!['status'], 'draft');
      expect(local['local_pending'], isTrue);
      expect(local['created_by'], 'u1');
      final upsert = outbox.entries.single;
      expect(upsert.kind, OutboxKind.upsert);
      expect(upsert.table, SyncTable.transactions);
      expect(upsert.transactionId, draft.id);
      expect(upsert.label, 'Draft · Diesel');

      device.online = true;
      final confirmed = await service.confirm('b1', draft.id, requestId: 'r-c');
      expect(confirmed.dataOrNull!.isQueued, isTrue);
      expect(outbox.entries.map((e) => e.kind), [
        OutboxKind.upsert,
        OutboxKind.confirm,
      ]);
      expect(rpc.calls, isEmpty);
      expect(tables.calls, isEmpty);
    });

    test('awaitServer online: the row goes to the server first, then the '
        'confirm runs directly', () async {
      final saved = await service.createDraft('b1', draft, awaitServer: true);
      expect(saved.isSuccess, isTrue);
      expect(tables.calls, ['upsert transactions']);
      expect(tables.rows('transactions').single['created_by'], 'u1');
      final local = await store.readRow(SyncTable.transactions, {
        'id': draft.id,
      });
      expect(local!['local_pending'], isFalse);
      expect(outbox.entries, isEmpty);

      await service.confirm('b1', draft.id, requestId: 'r-c');
      expect(calledFunctions(), ['confirm_transaction']);
    });

    test('awaitServer: a row level security refusal comes back inline and '
        'nothing is stored', () async {
      tables.refuse.add('transactions');
      final saved = await service.createDraft('b1', draft, awaitServer: true);
      expect(saved.errorOrNull!.kind, AppErrorKind.permissionDenied);
      expect(
        await store.readRow(SyncTable.transactions, {'id': draft.id}),
        isNull,
      );
      expect(outbox.entries, isEmpty);
    });

    test('awaitServer offline: refused as offline (the form then saves it '
        'locally)', () async {
      device.online = false;
      final saved = await service.createDraft('b1', draft, awaitServer: true);
      expect(saved.errorOrNull!.kind, AppErrorKind.offline);
    });

    test(
      'an edit is an update of the editable columns; delete is soft',
      () async {
        device.online = false;
        await service.createDraft('b1', draft);
        await service.updateDraft('b1', draft.copyWith(description: 'Petrol'));
        await service.deleteDraft('b1', draft.id);
        final [_, edit, delete] = outbox.entries;
        expect(edit.kind, OutboxKind.update);
        expect(edit.updates.single.match, {'id': draft.id});
        expect(edit.updates.single.values['description'], 'Petrol');
        expect(edit.updates.single.values.containsKey('created_by'), isFalse);
        expect(delete.updates.single.values.keys, ['deleted_at']);
        final local = await store.readRow(SyncTable.transactions, {
          'id': draft.id,
        });
        expect(local!['description'], 'Petrol');
        expect(local['deleted_at'], isNotNull);
      },
    );
  });
}
