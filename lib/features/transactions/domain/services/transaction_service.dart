import 'dart:async';

import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_identity.dart';
import 'package:business_ledger/core/sync/sync_queue.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_query_plan.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionRepository)
class TransactionService implements TransactionRepository {
  TransactionService(
    this._store,
    this._writer,
    this._identity,
    this._queue,
    this._engine,
  );

  final LocalStore _store;
  final LocalWriter _writer;
  final SyncIdentity _identity;
  final SyncQueue _queue;
  final SyncEngine _engine;

  AppDatabase get _db => _store.db;

  @override
  String newTransactionId(String businessId) => RequestIds.rowId();

  /// The local query for [filter]: every part of it runs in SQLite (search
  /// included), so a page is always [limit] matching entries.
  /// `TransactionFilter.apply` then re-checks and orders the page.
  SimpleSelectStatement<$TransactionsTable, TransactionRowData> queryFor(
    String businessId,
    TransactionFilter filter, {
    required int limit,
    required String today,
  }) {
    final query = _db.select(_db.transactions)
      ..where((t) {
        var where = t.businessId.equals(businessId) & t.deletedAt.isNull();
        if (filter.status case final status?) {
          where &= t.status.equals(status.key);
        }
        if (filter.type case final type?) where &= t.type.equals(type.key);
        if (filter.categoryId case final id?) where &= t.categoryId.equals(id);
        if (filter.projectId case final id?) where &= t.projectId.equals(id);
        if (filter.partyId case final id?) where &= t.partyId.equals(id);
        if (filter.from case final from?) {
          where &= t.date.isBiggerOrEqualValue(from);
        }
        if (filter.to case final to?) where &= t.date.isSmallerOrEqualValue(to);
        switch (filter.payment) {
          case null:
            break;
          case PaymentFilter.open:
            where &=
                t.status.equals(TransactionStatus.confirmed.key) &
                t.outstandingMinor.isBiggerThanValue(0);
          case PaymentFilter.overdue:
            where &=
                t.status.equals(TransactionStatus.confirmed.key) &
                t.outstandingMinor.isBiggerThanValue(0) &
                t.dueDate.isSmallerThanValue(today);
          case final PaymentFilter stored:
            where &= t.paymentStatus.equals(stored.stored!.key);
        }
        for (final word in TransactionSearch.words(filter.search)) {
          where &= _hasToken(word);
        }
        return where;
      })
      ..orderBy(_order(filter.sort))
      ..limit(limit);
    return query;
  }

  /// `search_tokens` (a JSON array) contains [word]. Words are lowercase
  /// letters and digits (`TransactionSearch.words`); quotes are escaped
  /// anyway.
  static Expression<bool> _hasToken(String word) => CustomExpression<bool>(
    'EXISTS (SELECT 1 FROM json_each(transactions.search_tokens) '
    "WHERE json_each.value = '${word.replaceAll("'", "''")}')",
  );

  static List<OrderClauseGenerator<$TransactionsTable>> _order(
    TransactionSort sort,
  ) => switch (sort) {
    TransactionSort.dateDesc => [
      (t) => OrderingTerm.desc(t.date),
      (t) => OrderingTerm.desc(t.createdAt),
    ],
    TransactionSort.dateAsc => [
      (t) => OrderingTerm.asc(t.date),
      (t) => OrderingTerm.asc(t.createdAt),
    ],
    TransactionSort.amountDesc => [
      (t) => OrderingTerm.desc(t.totalMinor),
      (t) => OrderingTerm.desc(t.date),
    ],
    TransactionSort.amountAsc => [
      (t) => OrderingTerm.asc(t.totalMinor),
      (t) => OrderingTerm.desc(t.date),
    ],
  };

  static List<LedgerTransaction> _transactions(
    List<TransactionRowData> rows,
  ) => [for (final row in rows) LedgerTransaction.fromRow(rowOf(row))];

  @override
  Stream<AppResult<TransactionPage>> watchTransactions(
    String businessId,
    TransactionFilter filter, {
    required int limit,
    required String today,
  }) => LocalStreams.watch(
    queryFor(businessId, filter, limit: limit, today: today).watch(),
    (rows) {
      final items = _transactions(rows);
      return TransactionPage(
        items: filter.apply(items, today),
        fetched: items.length,
        limit: limit,
        plan: TransactionQueryPlan.local,
      );
    },
  );

  @override
  Stream<AppResult<LedgerTransaction?>> watchTransaction(
    String businessId,
    String transactionId,
  ) => LocalStreams.single(
    (_db.select(_db.transactions)..where(
          (t) =>
              t.id.equals(transactionId) &
              t.businessId.equals(businessId) &
              t.deletedAt.isNull(),
        ))
        .watchSingleOrNull(),
    _store.watchPulled(),
    (row) => LedgerTransaction.fromRow(rowOf(row)),
  );

  @override
  Stream<AppResult<List<Settlement>>> watchSettlements(
    String businessId,
    String transactionId,
  ) => LocalStreams.watch(
    (_db.select(_db.settlements)
          ..where(
            (s) =>
                s.businessId.equals(businessId) &
                s.transactionId.equals(transactionId),
          )
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .watch(),
    (rows) => List<Settlement>.unmodifiable([
      for (final row in rows) Settlement.fromRow(rowOf(row)),
    ]),
  );

  @override
  Stream<AppResult<List<LedgerTransaction>>> watchLinked(
    String businessId,
    String transactionId,
  ) => LocalStreams.watch(
    (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.businessId.equals(businessId) &
                t.linkedTransactionId.equals(transactionId),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch(),
    (rows) => List<LedgerTransaction>.unmodifiable(_transactions(rows)),
  );

  @override
  Stream<AppResult<List<AuditEntry>>> watchAudit(
    String businessId,
    String entityId,
  ) => LocalStreams.watch(
    (_db.select(_db.auditLog)
          ..where(
            (a) =>
                a.businessId.equals(businessId) & a.entityId.equals(entityId),
          )
          ..orderBy([
            (a) => OrderingTerm.desc(a.at),
            (a) => OrderingTerm.desc(a.id),
          ])
          ..limit(50))
        .watch(),
    (rows) => List<AuditEntry>.unmodifiable([
      for (final row in rows) AuditEntry.fromRow(rowOf(row)),
    ]),
  );

  @override
  Future<void> refresh() async {
    try {
      await _engine.refresh().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // The list updates by itself when the pull lands.
    }
  }

  String? get _uid => _identity.uid;

  static const AppException _signedOut = CloudAvailability.signedOut;

  static String _draftLabel(TransactionDraft draft) {
    for (final candidate in [
      draft.description,
      draft.partyName,
      draft.categoryName,
    ]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return 'Draft · ${candidate.trim()}';
      }
    }
    return 'Draft · ${draft.type.label}';
  }

  @override
  Future<AppResult<void>> createDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  }) async {
    final uid = _uid;
    if (uid == null) return const Failure(_signedOut);
    return _writer.upsert(
      SyncTable.transactions,
      [draft.toRow(uid: uid, businessId: businessId, isNew: true)],
      businessId: businessId,
      transactionId: draft.id,
      label: _draftLabel(draft),
      awaitServer: awaitServer,
    );
  }

  @override
  Future<AppResult<void>> updateDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  }) async {
    final uid = _uid;
    if (uid == null) return const Failure(_signedOut);
    return _writer.update(
      SyncTable.transactions,
      [
        RowUpdate(
          {'id': draft.id},
          draft.toRow(uid: uid, businessId: businessId, isNew: false),
        ),
      ],
      businessId: businessId,
      transactionId: draft.id,
      label: _draftLabel(draft),
      awaitServer: awaitServer,
    );
  }

  /// A soft delete (`deleted_at`), so other devices learn about it.
  @override
  Future<AppResult<void>> deleteDraft(
    String businessId,
    String transactionId,
  ) => _writer.update(
    SyncTable.transactions,
    [
      RowUpdate(
        {'id': transactionId},
        {'deleted_at': DateTime.now().toUtc().toIso8601String()},
      ),
    ],
    businessId: businessId,
    transactionId: transactionId,
    label: 'Delete draft',
  );

  @override
  Future<AppResult<String>> duplicate(
    String businessId,
    LedgerTransaction source, {
    required String date,
  }) async {
    final id = newTransactionId(businessId);
    final draft = TransactionDraft.fromTransaction(
      source,
      fallbackDate: date,
    ).duplicateAs(id: id, date: date);
    final result = await createDraft(businessId, draft);
    return result.map((_) => id);
  }

  /// Parses an applied result; a queued one has nothing to parse yet.
  static AppResult<ActionOutcome<T>> _outcome<T>(
    AppResult<ActionOutcome<Map<String, dynamic>>> result,
    T Function(Map<String, dynamic> map) parse,
  ) {
    switch (result) {
      case Failure(:final error):
        return Failure(error);
      case Success(data: Queued(:final entry)):
        return Success(Queued(entry));
      case Success(data: Applied(result: final map)):
        try {
          return Success(Applied(parse(map)));
        } catch (error) {
          return Failure(AppException.from(error));
        }
    }
  }

  static String _labelOr(String label, String fallback) =>
      label.trim().isEmpty ? fallback : label.trim();

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
    final result = await _queue.run(
      QueueableCall(
        kind: OutboxKind.confirm,
        businessId: businessId,
        transactionId: transactionId,
        label: _labelOr(label, settleNow ? 'Confirm as paid' : 'Confirm'),
        payload: {
          'businessId': businessId,
          'transactionId': transactionId,
          'requestId': requestId,
          'expectedVersion': ?expectedVersion,
          if (settleNow) 'settleNow': true,
          if (settleNow) 'settleDate': ?settleDate,
          if (settleNow && (settleMethod?.trim().isNotEmpty ?? false))
            'settleMethod': settleMethod!.trim(),
        },
      ),
    );
    return _outcome(result, ConfirmResult.fromMap);
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
    final result = await _queue.run(
      QueueableCall(
        kind: OutboxKind.edit,
        businessId: businessId,
        transactionId: transactionId,
        label: _labelOr(label, 'Edit'),
        baseVersion: expectedVersion,
        payload: {
          'businessId': businessId,
          'transactionId': transactionId,
          'requestId': requestId,
          'expectedVersion': expectedVersion,
          'changes': changes,
        },
      ),
    );
    return _outcome(result, MutationResult.fromMap);
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
    final trimmed = reason?.trim() ?? '';
    final result = await _queue.run(
      QueueableCall(
        kind: OutboxKind.cancel,
        businessId: businessId,
        transactionId: transactionId,
        label: _labelOr(label, 'Cancel'),
        payload: {
          'businessId': businessId,
          'transactionId': transactionId,
          'requestId': requestId,
          'expectedVersion': ?expectedVersion,
          if (trimmed.isNotEmpty) 'reason': trimmed,
        },
      ),
    );
    return _outcome(result, MutationResult.fromMap);
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
    final result = await _queue.run(
      QueueableCall(
        kind: OutboxKind.settle,
        businessId: businessId,
        transactionId: transactionId,
        label: _labelOr(label, kind.label),
        payload: {
          'businessId': businessId,
          'transactionId': transactionId,
          'requestId': requestId,
          'kind': kind.key,
          'amountMinor': amountMinor,
          'date': date,
          if (method?.trim().isNotEmpty ?? false) 'method': method!.trim(),
          if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
          'expectedVersion': ?expectedVersion,
        },
      ),
    );
    return _outcome(result, SettlementResult.fromMap);
  }

  @override
  Stream<List<OutboxEntry>> watchQueued(String businessId) =>
      _engine.entries.map(
        (entries) => List<OutboxEntry>.unmodifiable(
          entries.where((entry) => entry.businessId == businessId),
        ),
      );
}
