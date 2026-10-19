import 'dart:async';

import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/repository/document_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

/// [DocumentRepository] over the `issue_document` RPC and the on-device
/// store. Documents are text only: the PDF is rendered on the device from
/// the stored snapshot whenever it is needed, and never stored.
@LazySingleton(as: DocumentRepository)
class DocumentService implements DocumentRepository {
  DocumentService(this._rpc, this._store, this._engine);

  final RpcClient _rpc;
  final LocalStore _store;
  final SyncEngine _engine;

  AppDatabase get _db => _store.db;

  @override
  Future<AppResult<IssueResult>> issue({
    required String businessId,
    required String transactionId,
    required DocumentType type,
    required String requestId,
    String? settlementId,
  }) async {
    final result = await _rpc.call('issueDocument', {
      'businessId': businessId,
      'transactionId': transactionId,
      'type': type.key,
      'requestId': requestId,
      'settlementId': ?settlementId,
    });
    switch (result) {
      case Success(:final data):
        // The document (and its snapshot) comes down before the caller
        // opens it.
        try {
          await _engine.refresh().timeout(const Duration(seconds: 10));
        } on TimeoutException {
          // `get` below says "not found" until it lands.
        }
        return AppResult.guard(() async => IssueResult.fromMap(data));
      case Failure(:final error):
        return Failure(error);
    }
  }

  @override
  Stream<AppResult<List<IssuedDocument>>> watchForTransaction(
    String businessId,
    String transactionId,
  ) => LocalStreams.watch(
    (_db.select(_db.documents)
          ..where(
            (d) =>
                d.businessId.equals(businessId) &
                d.transactionId.equals(transactionId),
          )
          ..orderBy([(d) => OrderingTerm.desc(d.issuedAt)]))
        .watch(),
    (rows) => [for (final row in rows) IssuedDocument.fromRow(rowOf(row))],
  );

  @override
  Future<AppResult<IssuedDocument>> get(
    String businessId,
    String documentId,
  ) => AppResult.guard(() async {
    final row = await _store.readRow(SyncTable.documents, {
      'business_id': businessId,
      'id': documentId,
    });
    if (row == null) {
      throw const AppException(
        kind: AppErrorKind.notFound,
        message: 'That document no longer exists.',
      );
    }
    return IssuedDocument.fromRow(row);
  });
}
