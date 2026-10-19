import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_queue.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/domain/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_fakes.dart';

class _Callable extends Mock implements CallableClient {}

class _Refs extends Mock implements FirestoreRefs {}

class _Writer extends Mock implements LocalFirstWriter {}

class _Auth extends Mock implements FirebaseAuth {}

class _Engine extends Mock implements SyncEngine {}

/// The repository's money paths over the real `SyncQueue`: direct when the
/// cloud is reachable, queued in the outbox otherwise.
void main() {
  late _Callable callable;
  late FakeConnectivityService device;
  late SyncSettings settings;
  late Outbox outbox;
  late FakeNetwork network;
  late TransactionService service;
  final calls = <(String, Map<String, Object?>)>[];
  final answers = <AppResult<Map<String, dynamic>>>[];

  setUpAll(() => registerFallbackValue(<String, Object?>{}));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    answers.clear();
    callable = _Callable();
    when(
      () => callable.call(
        any(),
        any(),
        requiresOnline: any(named: 'requiresOnline'),
      ),
    ).thenAnswer((invocation) async {
      calls.add((
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as Map<String, Object?>,
      ));
      return answers.isEmpty
          ? const Success({
              'settlementId': 'r-1',
              'transactionId': 't1',
              'version': 4,
              'paymentStatus': 'paid',
              'outstandingMinor': 0,
            })
          : answers.removeAt(0);
    });
    device = FakeConnectivityService();
    network = FakeNetwork();
    settings = SyncSettings(await SharedPreferences.getInstance(), network);
    final availability = CloudAvailability(device, settings);
    outbox = Outbox(MemoryOutboxStore());
    final queue = SyncQueue(
      callable,
      outbox,
      availability,
      network,
      FakeIdentity(),
      now: () => DateTime.utc(2026, 3, 14, 9),
      localWritesWait: const Duration(milliseconds: 20),
    );
    service = TransactionService(
      _Refs(),
      _Writer(),
      _Auth(),
      availability,
      queue,
      _Engine(),
    );
  });

  tearDown(() async {
    await outbox.dispose();
    await device.dispose();
  });

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

  test('online with sync on: calls directly and returns the result', () async {
    final result = await pay();
    final outcome = result.dataOrNull!;
    expect(outcome, isA<Applied<SettlementResult>>());
    expect(outcome.resultOrNull!.version, 4);
    expect(calls.single.$1, 'recordSettlement');
    expect(calls.single.$2['expectedVersion'], 3);
    expect(outbox.entries, isEmpty);
  });

  test(
    'offline: queued with the requestId, label and payload; no call',
    () async {
      device.online = false;
      final result = await pay();
      final entry = (result.dataOrNull! as Queued<SettlementResult>).entry;
      expect(calls, isEmpty);
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
    expect(calls, isEmpty);
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
      answers.add(
        const Failure(
          AppException(
            kind: AppErrorKind.timeout,
            code: 'deadline-exceeded',
            message: 'Too slow',
          ),
        ),
      );
      final result = await pay();
      expect(calls, hasLength(1));
      expect(result.dataOrNull!.isQueued, isTrue);
      expect(outbox.entries.single.id, 'r-1');
    },
  );

  test('a definitive refusal is returned, not queued', () async {
    answers.add(
      const Failure(
        AppException(
          kind: AppErrorKind.violation,
          code: 'failed-precondition',
          message: 'Too much',
        ),
      ),
    );
    final result = await pay();
    expect(result.errorOrNull!.kind, AppErrorKind.violation);
    expect(outbox.entries, isEmpty);
  });

  test('with an action already queued for the transaction, the next one '
      'queues behind it even online', () async {
    device.online = false;
    await pay();
    device.online = true;
    final second = await pay(requestId: 'r-2');
    expect(second.dataOrNull!.isQueued, isTrue);
    expect(calls, isEmpty);
    final other = await pay(requestId: 'r-3', transactionId: 't2');
    expect(other.dataOrNull!.isQueued, isFalse);
  });

  test(
    'local writes not on the server in time: the confirm is queued',
    () async {
      network.pendingWrites = Completer<void>();
      final result = await service.confirm('b1', 't1', requestId: 'r-c');
      expect(result.dataOrNull!.isQueued, isTrue);
      expect(calls, isEmpty);
      network.pendingWrites!.complete();
    },
  );
}
