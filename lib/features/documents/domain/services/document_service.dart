import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/repository/document_repository.dart';
import 'package:injectable/injectable.dart';

/// [DocumentRepository] over the `issueDocument` callable and Firestore.
/// Documents are text only: the PDF is rendered on the device from the
/// stored snapshot whenever it is needed, and never stored.
@LazySingleton(as: DocumentRepository)
class DocumentService implements DocumentRepository {
  DocumentService(this._callable, this._refs);

  final CallableClient _callable;
  final FirestoreRefs _refs;

  @override
  Future<AppResult<IssueResult>> issue({
    required String businessId,
    required String transactionId,
    required DocumentType type,
    required String requestId,
    String? settlementId,
  }) async {
    final result = await _callable.call('issueDocument', {
      'businessId': businessId,
      'transactionId': transactionId,
      'type': type.key,
      'requestId': requestId,
      'settlementId': ?settlementId,
    });
    return switch (result) {
      Success(:final data) => AppResult.guard(
        () async => IssueResult.fromMap(data),
      ),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Stream<AppResult<List<IssuedDocument>>> watchForTransaction(
    String businessId,
    String transactionId,
  ) => _refs
      .documents(businessId)
      .where('transactionId', isEqualTo: transactionId)
      .orderBy('issuedAt', descending: true)
      .snapshots()
      .transform(
        _results(
          (snapshot) => [
            for (final doc in snapshot.docs)
              IssuedDocument.fromMap(doc.id, doc.data()),
          ],
        ),
      );

  @override
  Future<AppResult<IssuedDocument>> get(
    String businessId,
    String documentId,
  ) => AppResult.guard(() async {
    final snapshot = await _refs.document(businessId, documentId).get();
    final data = snapshot.data();
    if (data == null) {
      throw const AppException(
        kind: AppErrorKind.notFound,
        message: 'That document no longer exists.',
      );
    }
    return IssuedDocument.fromMap(snapshot.id, data);
  });

  /// Maps each snapshot to a [Success], and a parse error or a stream error
  /// to a [Failure], without ending the stream.
  static StreamTransformer<S, AppResult<T>> _results<S, T>(
    T Function(S source) convert,
  ) => StreamTransformer.fromHandlers(
    handleData: (source, sink) {
      try {
        sink.add(Success(convert(source)));
      } catch (error) {
        sink.add(Failure(AppException.from(error)));
      }
    },
    handleError: (error, _, sink) =>
        sink.add(Failure(AppException.from(error))),
  );
}
