import 'dart:async';
import 'dart:typed_data';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
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

/// A recorded callable: its name, request id and payload.
class CallRecord {
  CallRecord(this.name, this.requestId, [this.data = const {}]);

  final String name;
  final String requestId;
  final Map<String, Object?> data;
}

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
  AppResult<String> duplicateResult = const Success('t-copy');

  final List<CallRecord> calls = [];
  final List<AppResult<ConfirmResult>> confirmResults = [];
  final List<AppResult<MutationResult>> editResults = [];
  final List<AppResult<MutationResult>> cancelResults = [];
  final List<AppResult<SettlementResult>> settleResults = [];

  AppResult<String> uploadResult = const Success(
    'businesses/b1/attachments/t1/1_bill.pdf',
  );
  int uploads = 0;

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
    return writeResult;
  }

  @override
  Future<AppResult<void>> updateDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  }) async {
    updated.add(draft);
    awaitedServer.add(awaitServer);
    return writeResult;
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
  Future<AppResult<ConfirmResult>> confirm(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    bool settleNow = false,
    String? settleDate,
    String? settleMethod,
  }) async {
    calls.add(
      CallRecord('confirm', requestId, {
        'transactionId': transactionId,
        'expectedVersion': expectedVersion,
        'settleNow': settleNow,
        'settleDate': settleDate,
      }),
    );
    return confirmResults.isEmpty
        ? Success(
            ConfirmResult(
              transactionId: transactionId,
              version: 1,
              settlementId: settleNow ? requestId : null,
            ),
          )
        : confirmResults.removeAt(0);
  }

  @override
  Future<AppResult<MutationResult>> editConfirmed(
    String businessId,
    String transactionId, {
    required String requestId,
    required int expectedVersion,
    required Map<String, Object?> changes,
  }) async {
    calls.add(
      CallRecord('edit', requestId, {
        'expectedVersion': expectedVersion,
        'changes': changes,
      }),
    );
    return editResults.isEmpty
        ? Success(MutationResult(transactionId: transactionId, version: 2))
        : editResults.removeAt(0);
  }

  @override
  Future<AppResult<MutationResult>> cancel(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    String? reason,
  }) async {
    calls.add(
      CallRecord('cancel', requestId, {
        'expectedVersion': expectedVersion,
        'reason': reason,
      }),
    );
    return cancelResults.isEmpty
        ? Success(MutationResult(transactionId: transactionId, version: 2))
        : cancelResults.removeAt(0);
  }

  @override
  Future<AppResult<SettlementResult>> recordSettlement(
    String businessId,
    String transactionId, {
    required String requestId,
    required SettlementKind kind,
    required int amountMinor,
    required String date,
    String? method,
    String? note,
    int? expectedVersion,
  }) async {
    calls.add(
      CallRecord('settle', requestId, {
        'kind': kind,
        'amountMinor': amountMinor,
        'date': date,
        'method': method,
        'expectedVersion': expectedVersion,
      }),
    );
    return settleResults.isEmpty
        ? Success(
            SettlementResult(
              settlementId: requestId,
              transactionId: transactionId,
              version: 2,
            ),
          )
        : settleResults.removeAt(0);
  }

  @override
  Future<AppResult<String>> uploadAttachment(
    String businessId,
    String transactionId,
    PickedAttachment file,
  ) async {
    uploads++;
    return uploadResult;
  }

  @override
  Future<AppResult<Uint8List>> downloadAttachment(String path) async =>
      Success(Uint8List(0));

  Future<void> dispose() async {
    await pages.close();
    for (final controller in transactions.values) {
      await controller.close();
    }
    await settlements.close();
    await linked.close();
    await audit.close();
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

class _MockConnectivity extends Mock implements ConnectivityService {}

/// A [ConnectivityService] whose state the test sets.
class FakeConnectivity {
  FakeConnectivity({this.isOnline = true}) {
    when(() => service.isOnline).thenAnswer((_) => isOnline);
    when(() => service.onlineChanges).thenAnswer((_) => _changes.stream);
    when(service.refresh).thenAnswer((_) async => isOnline);
  }

  final ConnectivityService service = _MockConnectivity();
  final StreamController<bool> _changes = StreamController.broadcast();
  bool isOnline;

  void setOnline({required bool online}) {
    isOnline = online;
    _changes.add(online);
  }

  Future<void> dispose() => _changes.close();
}
