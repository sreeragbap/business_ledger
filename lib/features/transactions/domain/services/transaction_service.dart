import 'dart:async';
import 'dart:typed_data';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionRepository)
class TransactionService implements TransactionRepository {
  TransactionService(
    this._refs,
    this._callable,
    this._writer,
    this._auth,
    this._storage,
    this._connectivity,
  );

  final FirestoreRefs _refs;
  final CallableClient _callable;
  final LocalFirstWriter _writer;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final ConnectivityService _connectivity;

  /// `businesses/{bid}/attachments/{tid}/{file}`, as `storage.rules` expects.
  static String attachmentPath(
    String businessId,
    String transactionId,
    String fileName,
  ) =>
      '${FirestoreRefs.storagePrefix(businessId)}/attachments/'
      '$transactionId/$fileName';

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
    if (!await _connectivity.refresh()) {
      return const Failure(AppException.offline());
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
    final result = await _callable.call('confirmTransaction', {
      'businessId': businessId,
      'transactionId': transactionId,
      'requestId': requestId,
      'expectedVersion': ?expectedVersion,
      if (settleNow) 'settleNow': true,
      if (settleNow) 'settleDate': ?settleDate,
      if (settleNow && (settleMethod?.trim().isNotEmpty ?? false))
        'settleMethod': settleMethod!.trim(),
    });
    return result.map(ConfirmResult.fromMap);
  }

  @override
  Future<AppResult<MutationResult>> editConfirmed(
    String businessId,
    String transactionId, {
    required String requestId,
    required int expectedVersion,
    required Map<String, Object?> changes,
  }) async {
    final result = await _callable.call('editConfirmedTransaction', {
      'businessId': businessId,
      'transactionId': transactionId,
      'requestId': requestId,
      'expectedVersion': expectedVersion,
      'changes': changes,
    });
    return result.map(MutationResult.fromMap);
  }

  @override
  Future<AppResult<MutationResult>> cancel(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    String? reason,
  }) async {
    final trimmed = reason?.trim() ?? '';
    final result = await _callable.call('cancelTransaction', {
      'businessId': businessId,
      'transactionId': transactionId,
      'requestId': requestId,
      'expectedVersion': ?expectedVersion,
      if (trimmed.isNotEmpty) 'reason': trimmed,
    });
    return result.map(MutationResult.fromMap);
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
    final result = await _callable.call('recordSettlement', {
      'businessId': businessId,
      'transactionId': transactionId,
      'requestId': requestId,
      'kind': kind.key,
      'amountMinor': amountMinor,
      'date': date,
      if (method?.trim().isNotEmpty ?? false) 'method': method!.trim(),
      if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
      'expectedVersion': ?expectedVersion,
    });
    return result.map(SettlementResult.fromMap);
  }

  @override
  Future<AppResult<String>> uploadAttachment(
    String businessId,
    String transactionId,
    PickedAttachment file,
  ) async {
    if (!await _connectivity.refresh()) {
      return const Failure(AppException.offline());
    }
    final safeName = file.name.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = attachmentPath(
      businessId,
      transactionId,
      '${stamp}_$safeName',
    );
    return AppResult.guard(() async {
      await _storage
          .ref(path)
          .putData(file.bytes, SettableMetadata(contentType: file.contentType));
      return path;
    });
  }

  @override
  Future<AppResult<Uint8List>> downloadAttachment(String path) =>
      AppResult.guard(() async {
        final bytes = await _storage.ref(path).getData();
        if (bytes == null) {
          throw const AppException(
            kind: AppErrorKind.notFound,
            message: 'That attachment is no longer available.',
          );
        }
        return bytes;
      });
}
