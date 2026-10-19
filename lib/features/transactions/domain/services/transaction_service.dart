import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_queue.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_query_plan.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionRepository)
class TransactionService implements TransactionRepository {
  TransactionService(
    this._refs,
    this._writer,
    this._auth,
    this._availability,
    this._queue,
    this._engine,
  );

  final FirestoreRefs _refs;
  final LocalFirstWriter _writer;
  final FirebaseAuth _auth;
  final CloudAvailability _availability;
  final SyncQueue _queue;
  final SyncEngine _engine;

  @override
  String newTransactionId(String businessId) =>
      _refs.transactions(businessId).doc().id;

  /// The Firestore query for [plan]. Every shape it can produce has an index
  /// (see `TransactionQueryPlan`).
  Query<JsonMap> queryFor(
    String businessId,
    TransactionQueryPlan plan,
    int limit,
  ) {
    Query<JsonMap> query = _refs.transactions(businessId);
    for (final entry in plan.equals.entries) {
      query = query.where(entry.key, isEqualTo: entry.value);
    }
    if (plan.searchToken case final token?) {
      query = query.where('searchTokens', arrayContains: token);
    }
    if (plan.openOnly) query = query.where('isOpen', isEqualTo: true);
    if (plan.dueBefore case final day?) {
      query = query.where(TransactionQueryPlan.dueField, isLessThan: day);
    }
    if (plan.orderBy == TransactionQueryPlan.dateField) {
      if (plan.from case final from?) {
        query = query.where(
          TransactionQueryPlan.dateField,
          isGreaterThanOrEqualTo: LedgerDates.timestamp(from),
        );
      }
      if (plan.to case final to?) {
        query = query.where(
          TransactionQueryPlan.dateField,
          isLessThanOrEqualTo: LedgerDates.timestamp(to),
        );
      }
    }
    return query
        .orderBy(plan.orderBy, descending: plan.descending)
        .limit(limit);
  }

  @override
  Stream<AppResult<TransactionPage>> watchTransactions(
    String businessId,
    TransactionFilter filter, {
    required int limit,
    required String today,
  }) {
    final plan = TransactionQueryPlan.of(filter, today: today);
    return FirestoreStreams.list(
      queryFor(businessId, plan, limit),
      LedgerTransaction.fromFirestore,
    ).map(
      (result) => result.map(
        (docs) => TransactionPage(
          items: filter.apply(docs, today),
          fetched: docs.length,
          limit: limit,
          plan: plan,
        ),
      ),
    );
  }

  @override
  Stream<AppResult<LedgerTransaction?>> watchTransaction(
    String businessId,
    String transactionId,
  ) => FirestoreStreams.doc(
    _refs.transaction(businessId, transactionId),
    LedgerTransaction.fromFirestore,
  );

  @override
  Stream<AppResult<List<Settlement>>> watchSettlements(
    String businessId,
    String transactionId,
  ) => FirestoreStreams.list(
    _refs
        .settlements(businessId, transactionId)
        .orderBy('createdAt', descending: true),
    Settlement.fromFirestore,
  );

  @override
  Stream<AppResult<List<LedgerTransaction>>> watchLinked(
    String businessId,
    String transactionId,
  ) => FirestoreStreams.list(
    _refs
        .transactions(businessId)
        .where('linkedTransactionId', isEqualTo: transactionId)
        .orderBy(TransactionQueryPlan.dateField, descending: true),
    LedgerTransaction.fromFirestore,
  );

  @override
  Stream<AppResult<List<AuditEntry>>> watchAudit(
    String businessId,
    String entityId,
  ) => FirestoreStreams.list(
    _refs
        .audit(businessId)
        .where('entityId', isEqualTo: entityId)
        .orderBy('at', descending: true)
        .limit(50),
    AuditEntry.fromFirestore,
  );

  String? get _uid => _auth.currentUser?.uid;

  static const AppException _signedOut = AppException(
    kind: AppErrorKind.unauthenticated,
    message: 'Your session has ended. Sign in again.',
  );

  Future<AppResult<void>> _write(
    Future<void> Function() write, {
    required bool awaitServer,
  }) async {
    if (!awaitServer) return _writer.commit(write);
    if (!await _availability.refresh()) {
      return Failure(_availability.unavailableError);
    }
    return AppResult.guard(() => write().timeout(CallableClient.timeout));
  }

  @override
  Future<AppResult<void>> createDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  }) {
    final uid = _uid;
    if (uid == null) return Future.value(const Failure(_signedOut));
    final ref = _refs.transaction(businessId, draft.id);
    final data = draft.toMap(
      uid: uid,
      isNew: true,
      now: FieldValue.serverTimestamp(),
    );
    return _write(() => ref.set(data), awaitServer: awaitServer);
  }

  @override
  Future<AppResult<void>> updateDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  }) {
    final uid = _uid;
    if (uid == null) return Future.value(const Failure(_signedOut));
    final ref = _refs.transaction(businessId, draft.id);
    final data = draft.toMap(
      uid: uid,
      isNew: false,
      now: FieldValue.serverTimestamp(),
    );
    return _write(() => ref.update(data), awaitServer: awaitServer);
  }

  @override
  Future<AppResult<void>> deleteDraft(
    String businessId,
    String transactionId,
  ) => _writer.commit(
    () => _refs.transaction(businessId, transactionId).delete(),
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
