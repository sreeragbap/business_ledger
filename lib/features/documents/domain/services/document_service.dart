import 'dart:async';
import 'dart:typed_data';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/repository/document_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

/// [DocumentRepository] over the `issueDocument` callable, Firestore and
/// Storage.
@LazySingleton(as: DocumentRepository)
class DocumentService implements DocumentRepository {
  DocumentService(
    this._callable,
    this._refs,
    this._storage,
    this._connectivity,
  );

  final CallableClient _callable;
  final FirestoreRefs _refs;
  final FirebaseStorage _storage;
  final ConnectivityService _connectivity;

  /// `businesses/{bid}/documents/{docId}.pdf`, as `storage.rules` expects.
  static String storagePathFor(String businessId, String documentId) =>
      '${FirestoreRefs.storagePrefix(businessId)}/'
      '${FirestoreRefs.documentsPath}/$documentId.pdf';

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

  @override
  Future<AppResult<String>> attachPdf({
    required String businessId,
    required IssuedDocument document,
    required Uint8List bytes,
  }) async {
    if (document.isUploaded) return Success(document.storagePath!);
    if (!await _connectivity.refresh()) {
      return const Failure(AppException.offline());
    }
    return AppResult.guard(() async {
      final path = storagePathFor(businessId, document.id);
      final ref = _storage.ref(path);
      // Storage rules allow create but not overwrite, so a previous attempt
      // that uploaded the file and then failed to record it must not upload
      // again.
      if (!await _exists(ref)) {
        await ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'application/pdf',
            customMetadata: {'number': document.number},
          ),
        );
      }
      // Rules allow a client to change exactly this one field.
      await _refs.document(businessId, document.id).update({
        'storagePath': path,
      });
      return path;
    });
  }

  static Future<bool> _exists(Reference ref) async {
    try {
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (error) {
      if (AppException.normaliseCode(error.code) == 'object-not-found') {
        return false;
      }
      rethrow;
    }
  }

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
