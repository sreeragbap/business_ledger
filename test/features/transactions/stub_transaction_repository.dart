import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/domain/repository/project_repository.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_query_plan.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';

/// One `watchTransactions` subscription, as the cubit asked for it.
class WatchCall {
  WatchCall(this.filter, this.limit, this.today);

  final TransactionFilter filter;
  final int limit;
  final String today;
}

/// A recorded callable: its name, request id, payload and queue label.
class CallRecord {
  CallRecord(
    this.name,
    this.requestId, [
    this.data = const {},
    this.label = '',
  ]);

  final String name;
  final String requestId;
  final Map<String, Object?> data;
  final String label;
}

/// A queued entry as the stub hands it back when [StubTransactionRepository]
/// is set to queue.
OutboxEntry queuedEntry(
  String requestId, {
  OutboxKind kind = OutboxKind.settle,
  String transactionId = 't1',
  String label = '',
  OutboxStatus status = OutboxStatus.pending,
  OutboxError? error,
  Map<String, Object?> payload = const {},
}) => OutboxEntry(
  id: requestId,
  uid: 'u1',
  businessId: 'b1',
  kind: kind,
  payload: {'requestId': requestId, ...payload},
  transactionId: transactionId,
  label: label,
  createdAt: DateTime.utc(2026, 3, 14, 9),
  status: status,
  lastError: error,
);

/// Hand-written [TransactionRepository]. Push stream values through the
/// controllers; queue results in the `*Results` lists (or set the single
/// `*Result`); read the recorded calls afterwards.
class StubTransactionRepository extends TransactionRepository {
  final List<WatchCall> watchCalls = [];
  StreamController<AppResult<TransactionPage>> pages =
      StreamController.broadcast();

  final Map<String, StreamController<AppResult<LedgerTransaction?>>>
  transactions = {};
  StreamController<AppResult<LedgerTransaction?>> transaction(String id) =>
      transactions.putIfAbsent(id, StreamController.broadcast);

  /// Replayed to each new `watchTransaction` listener, like a cached doc.
  final Map<String, AppResult<LedgerTransaction?>> latest = {};

  final StreamController<AppResult<List<Settlement>>> settlements =
      StreamController.broadcast();
  final StreamController<AppResult<List<LedgerTransaction>>> linked =
      StreamController.broadcast();
  final StreamController<AppResult<List<AuditEntry>>> audit =
      StreamController.broadcast();
  int auditWatches = 0;

  int _ids = 0;
  final List<TransactionDraft> created = [];
  final List<TransactionDraft> updated = [];
  final List<bool> awaitedServer = [];
  final List<String> deleted = [];
  AppResult<void> writeResult = const Success(null);

  /// Answers for create/update, in order, before falling back to
  /// [writeResult].
  final List<AppResult<void>> writeResults = [];

  AppResult<void> _nextWrite() =>
      writeResults.isEmpty ? writeResult : writeResults.removeAt(0);
  AppResult<String> duplicateResult = const Success('t-copy');

  final List<CallRecord> calls = [];
  final List<AppResult<ConfirmResult>> confirmResults = [];
  final List<AppResult<MutationResult>> editResults = [];
  final List<AppResult<MutationResult>> cancelResults = [];
  final List<AppResult<SettlementResult>> settleResults = [];

  /// Answer money actions as queued in the outbox, the way the
  /// service does offline or with sync off.
  bool queueActions = false;

  /// What `watchQueued` emits.
  final StreamController<List<OutboxEntry>> queued =
      StreamController.broadcast();

  AppResult<ActionOutcome<T>> _respond<T>(
    String name,
    String requestId,
    String label,
    String transactionId,
    AppResult<T> Function() applied,
  ) {
    if (queueActions) {
      return Success(
        Queued<T>(
          queuedEntry(
            requestId,
            kind: switch (name) {
              'confirm' => OutboxKind.confirm,
              'edit' => OutboxKind.edit,
              'cancel' => OutboxKind.cancel,
              _ => OutboxKind.settle,
            },
            transactionId: transactionId,
            label: label,
          ),
        ),
      );
    }
    return applied().map(Applied<T>.new);
  }

  @override
  String newTransactionId(String businessId) => 't-new-${_ids++}';

  @override
  Stream<AppResult<TransactionPage>> watchTransactions(
    String businessId,
    TransactionFilter filter, {
    required int limit,
    required String today,
  }) {
    watchCalls.add(WatchCall(filter, limit, today));
    return pages.stream;
  }

  /// Emits a page the way the service would: [docs] as fetched, then the
  /// filter applied on the device.
  void emitPage(List<LedgerTransaction> docs, {int? fetched}) {
    final call = watchCalls.last;
    pages.add(
      Success(
        TransactionPage(
          items: call.filter.apply(docs, call.today),
          fetched: fetched ?? docs.length,
          limit: call.limit,
          plan: TransactionQueryPlan.of(call.filter, today: call.today),
        ),
      ),
    );
  }

  void emitTransaction(LedgerTransaction tx) {
    latest[tx.id] = Success(tx);
    transaction(tx.id).add(Success(tx));
  }

  @override
  Stream<AppResult<LedgerTransaction?>> watchTransaction(
    String businessId,
    String transactionId,
  ) async* {
    final cached = latest[transactionId];
    if (cached != null) yield cached;
    yield* transaction(transactionId).stream;
  }

  @override
  Stream<AppResult<List<Settlement>>> watchSettlements(
    String businessId,
    String transactionId,
  ) => settlements.stream;

  @override
  Stream<AppResult<List<LedgerTransaction>>> watchLinked(
    String businessId,
    String transactionId,
  ) => linked.stream;

  @override
  Stream<AppResult<List<AuditEntry>>> watchAudit(
    String businessId,
    String entityId,
  ) {
    auditWatches++;
    return audit.stream;
  }

  @override
  Future<AppResult<void>> createDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  }) async {
    created.add(draft);
    awaitedServer.add(awaitServer);
    return _nextWrite();
  }

  @override
  Future<AppResult<void>> updateDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  }) async {
    updated.add(draft);
    awaitedServer.add(awaitServer);
    return _nextWrite();
  }

  @override
  Future<AppResult<void>> deleteDraft(
    String businessId,
    String transactionId,
  ) async {
    deleted.add(transactionId);
    return writeResult;
  }

  @override
  Future<AppResult<String>> duplicate(
    String businessId,
    LedgerTransaction source, {
    required String date,
  }) async => duplicateResult;

  @override
  Future<AppResult<ActionOutcome<ConfirmResult>>> confirm(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    bool settleNow = false,
    String? settleDate,
    String? settleMethod,
    String label = '',
  }) async {
    calls.add(
      CallRecord('confirm', requestId, {
        'transactionId': transactionId,
        'expectedVersion': expectedVersion,
        'settleNow': settleNow,
        'settleDate': settleDate,
      }, label),
    );
    return _respond(
      'confirm',
      requestId,
      label,
      transactionId,
      () => confirmResults.isEmpty
          ? Success(
              ConfirmResult(
                transactionId: transactionId,
                version: 1,
                settlementId: settleNow ? requestId : null,
              ),
            )
          : confirmResults.removeAt(0),
    );
  }

  @override
  Future<AppResult<ActionOutcome<MutationResult>>> editConfirmed(
    String businessId,
    String transactionId, {
    required String requestId,
    required int expectedVersion,
    required Map<String, Object?> changes,
    String label = '',
  }) async {
    calls.add(
      CallRecord('edit', requestId, {
        'expectedVersion': expectedVersion,
        'changes': changes,
      }, label),
    );
    return _respond(
      'edit',
      requestId,
      label,
      transactionId,
      () => editResults.isEmpty
          ? Success(MutationResult(transactionId: transactionId, version: 2))
          : editResults.removeAt(0),
    );
  }

  @override
  Future<AppResult<ActionOutcome<MutationResult>>> cancel(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    String? reason,
    String label = '',
  }) async {
    calls.add(
      CallRecord('cancel', requestId, {
        'expectedVersion': expectedVersion,
        'reason': reason,
      }, label),
    );
    return _respond(
      'cancel',
      requestId,
      label,
      transactionId,
      () => cancelResults.isEmpty
          ? Success(MutationResult(transactionId: transactionId, version: 2))
          : cancelResults.removeAt(0),
    );
  }

  @override
  Future<AppResult<ActionOutcome<SettlementResult>>> recordSettlement(
    String businessId,
    String transactionId, {
    required String requestId,
    required SettlementKind kind,
    required int amountMinor,
    required String date,
    String? method,
    String? note,
    int? expectedVersion,
    String label = '',
  }) async {
    calls.add(
      CallRecord('settle', requestId, {
        'kind': kind,
        'amountMinor': amountMinor,
        'date': date,
        'method': method,
        'expectedVersion': expectedVersion,
      }, label),
    );
    return _respond(
      'settle',
      requestId,
      label,
      transactionId,
      () => settleResults.isEmpty
          ? Success(
              SettlementResult(
                settlementId: requestId,
                transactionId: transactionId,
                version: 2,
              ),
            )
          : settleResults.removeAt(0),
    );
  }

  @override
  Stream<List<OutboxEntry>> watchQueued(String businessId) => queued.stream;

  Future<void> dispose() async {
    await pages.close();
    for (final controller in transactions.values) {
      await controller.close();
    }
    await settlements.close();
    await linked.close();
    await audit.close();
    await queued.close();
  }
}

class StubProjectRepository extends ProjectRepository {
  final StreamController<AppResult<List<Project>>> projects =
      StreamController.broadcast();

  @override
  Stream<AppResult<List<Project>>> watchProjects(String businessId) =>
      projects.stream;

  @override
  Future<AppResult<Project?>> getProject(String businessId, String id) async =>
      const Success(null);

  @override
  Future<AppResult<String>> create(String businessId, Project project) async =>
      const Success('pr-new');

  @override
  Future<AppResult<void>> update(String businessId, Project project) async =>
      const Success(null);

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  }) async => const Success(null);

  Future<void> dispose() => projects.close();
}

class _MockAvailability extends Mock implements CloudAvailability {}

/// A [CloudAvailability] (online and sync on) whose state the test sets.
class FakeConnectivity {
  FakeConnectivity({this.isOnline = true}) {
    when(() => service.isOnline).thenAnswer((_) => isOnline);
    when(() => service.onlineChanges).thenAnswer((_) => _changes.stream);
    when(service.refresh).thenAnswer((_) async => isOnline);
  }

  final CloudAvailability service = _MockAvailability();
  final StreamController<bool> _changes = StreamController.broadcast();
  bool isOnline;

  void setOnline({required bool online}) {
    isOnline = online;
    _changes.add(online);
  }

  Future<void> dispose() => _changes.close();
}
