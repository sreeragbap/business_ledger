import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/close_guard.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/repository/document_output.dart';
import 'package:business_ledger/features/documents/domain/repository/document_renderer.dart';
import 'package:business_ledger/features/documents/domain/repository/document_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'document_state.dart';

/// Issue → render → preview, then share or print/save. The PDF is rendered
/// on the device from the stored snapshot each time; it is never stored.
///
/// Issuing needs a connection (it allocates a gap-free number on the
/// server); rendering an already issued document works offline from its
/// cached snapshot.
@injectable
class DocumentCubit extends Cubit<DocumentState>
    with CloseGuard<DocumentState> {
  DocumentCubit(
    this._repository,
    this._renderer,
    this._output, {
    @ignoreParam String Function()? nextRequestId,
  }) : _nextRequestId = nextRequestId ?? RequestIds.next,
       super(const DocumentState());

  final DocumentRepository _repository;
  final DocumentRenderer _renderer;
  final DocumentOutput _output;
  final String Function() _nextRequestId;

  StreamSubscription<AppResult<List<IssuedDocument>>>? _watch;

  /// The issue the user asked for and has not yet seen succeed. A retry of
  /// the same document reuses its request id, so a timed-out call that did
  /// land on the server returns the original number instead of a second one.
  ({String key, String requestId})? _pendingIssue;

  /// Follows the documents issued for one transaction.
  Future<void> watchTransaction(String businessId, String transactionId) async {
    await _watch?.cancel();
    if (isClosing) return;
    emit(
      state.copyWith(
        businessId: businessId,
        watchStatus: const Status.loading(),
      ),
    );
    _watch = _repository
        .watchForTransaction(businessId, transactionId)
        .listen(
          (result) => result.when(
            success: (documents) => emit(
              state.copyWith(
                documents: documents,
                watchStatus: const Status.success(),
              ),
            ),
            failure: (error) =>
                emit(state.copyWith(watchStatus: Status.fromException(error))),
          ),
        );
  }

  /// Issues the document (or fetches the one already issued), then renders
  /// it for preview.
  Future<void> issue({
    required String businessId,
    required String transactionId,
    required DocumentType type,
    String? settlementId,
  }) async {
    if (state.issueStatus.isLoading) return;
    final key = IssuedDocument.idFor(
      type: type,
      transactionId: transactionId,
      settlementId: settlementId,
    );
    final pending = _pendingIssue;
    final requestId = pending != null && pending.key == key
        ? pending.requestId
        : _nextRequestId();
    _pendingIssue = (key: key, requestId: requestId);

    emit(
      state.copyWith(
        businessId: businessId,
        issueStatus: const Status.loading(),
      ),
    );
    final issued = await _repository.issue(
      businessId: businessId,
      transactionId: transactionId,
      type: type,
      settlementId: settlementId,
      requestId: requestId,
    );
    if (issued.errorOrNull case final error?) {
      // A refusal (cancelled, not confirmed) will not change on retry; only
      // an unknown outcome keeps the id for the next attempt.
      if (!_mayHaveLanded(error)) _pendingIssue = null;
      emit(state.copyWith(issueStatus: Status.fromException(error)));
      return;
    }
    _pendingIssue = null;

    final documentId = issued.dataOrNull!.documentId;
    final fetched = await _repository.get(businessId, documentId);
    switch (fetched) {
      case Success(:final data):
        emit(state.copyWith(issueStatus: const Status.success()));
        await open(data);
      case Failure(:final error):
        emit(state.copyWith(issueStatus: Status.fromException(error)));
    }
  }

  /// Opens a document by id (from the local cache when offline).
  Future<void> openById(String businessId, String documentId) async {
    emit(
      state.copyWith(
        businessId: businessId,
        renderStatus: const Status.loading(),
      ),
    );
    final fetched = await _repository.get(businessId, documentId);
    switch (fetched) {
      case Success(:final data):
        await open(data);
      case Failure(:final error):
        emit(state.copyWith(renderStatus: Status.fromException(error)));
    }
  }

  /// Renders [document] for preview. Needs no connection.
  Future<void> open(IssuedDocument document) async {
    emit(
      state.copyWith(
        document: document,
        clearPdf: state.document?.id != document.id,
        renderStatus: const Status.loading(),
        shareStatus: const Status.initial(),
        printStatus: const Status.initial(),
      ),
    );
    try {
      final bytes = await _renderer.render(document);
      emit(state.copyWith(pdf: bytes, renderStatus: const Status.success()));
    } catch (error) {
      emit(
        state.copyWith(
          renderStatus: Status.fromException(_renderFailure(error)),
        ),
      );
    }
  }

  Future<void> share() async {
    final (document, pdf) = (state.document, state.pdf);
    if (document == null || pdf == null || state.shareStatus.isLoading) return;
    emit(state.copyWith(shareStatus: const Status.loading()));
    try {
      await _output.share(pdf, fileName: document.fileName);
      emit(state.copyWith(shareStatus: const Status.success()));
    } catch (error) {
      emit(
        state.copyWith(
          shareStatus: Status.fromException(AppException.from(error)),
        ),
      );
    }
  }

  Future<void> printOrSave() async {
    final (document, pdf) = (state.document, state.pdf);
    if (document == null || pdf == null || state.printStatus.isLoading) return;
    emit(state.copyWith(printStatus: const Status.loading()));
    try {
      final done = await _output.printOrSave(pdf, name: document.number);
      emit(
        state.copyWith(
          printStatus: done ? const Status.success() : const Status.initial(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          printStatus: Status.fromException(AppException.from(error)),
        ),
      );
    }
  }

  static bool _mayHaveLanded(AppException error) =>
      error.kind == AppErrorKind.timeout ||
      error.kind == AppErrorKind.offline ||
      error.kind == AppErrorKind.unknown;

  static AppException _renderFailure(Object error) => error is AppException
      ? error
      : AppException(
          kind: AppErrorKind.unknown,
          message: "Couldn't prepare the PDF. Please try again.",
          cause: error.toString(),
        );

  @override
  Future<void> close() async {
    beginClose();
    await _watch?.cancel();
    return super.close();
  }
}
