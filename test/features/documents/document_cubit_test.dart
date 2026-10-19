import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/repository/document_output.dart';
import 'package:business_ledger/features/documents/domain/repository/document_renderer.dart';
import 'package:business_ledger/features/documents/domain/repository/document_repository.dart';
import 'package:business_ledger/features/documents/logic/document_cubit/document_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'document_fixtures.dart';

class _StubDocumentRepository extends DocumentRepository {
  final List<String> issueRequestIds = [];
  final List<AppResult<IssueResult>> issueResults = [];
  AppResult<IssuedDocument> getResult = Success(invoice());
  final StreamController<AppResult<List<IssuedDocument>>> watched =
      StreamController.broadcast();

  @override
  Future<AppResult<IssueResult>> issue({
    required String businessId,
    required String transactionId,
    required DocumentType type,
    required String requestId,
    String? settlementId,
  }) async {
    issueRequestIds.add(requestId);
    return issueResults.removeAt(0);
  }

  @override
  Stream<AppResult<List<IssuedDocument>>> watchForTransaction(
    String businessId,
    String transactionId,
  ) => watched.stream;

  @override
  Future<AppResult<IssuedDocument>> get(
    String businessId,
    String documentId,
  ) async => getResult;
}

class _StubRenderer extends DocumentRenderer {
  Error? error;
  int calls = 0;

  @override
  Future<Uint8List> render(IssuedDocument document) async {
    calls++;
    if (error != null) throw error!;
    return Uint8List.fromList(List.filled(10, 1));
  }
}

class _StubOutput extends DocumentOutput {
  final List<String> shared = [];
  final List<String> printed = [];
  bool printResult = true;

  @override
  Future<bool> share(Uint8List bytes, {required String fileName}) async {
    shared.add(fileName);
    return true;
  }

  @override
  Future<bool> printOrSave(Uint8List bytes, {required String name}) async {
    printed.add(name);
    return printResult;
  }
}

const Success<IssueResult> _issued = Success(
  IssueResult(
    documentId: 'invoice-tx1-main',
    number: 'INV-2026-0007',
    created: true,
  ),
);

void main() {
  late _StubDocumentRepository repository;
  late _StubRenderer renderer;
  late _StubOutput output;
  var ids = 0;

  DocumentCubit build() => DocumentCubit(
    repository,
    renderer,
    output,
    nextRequestId: () => 'request${ids++}',
  );

  setUp(() {
    repository = _StubDocumentRepository();
    renderer = _StubRenderer();
    output = _StubOutput();
    ids = 0;
  });

  Future<void> issueInvoice(DocumentCubit cubit) => cubit.issue(
    businessId: 'b1',
    transactionId: 'tx1',
    type: DocumentType.invoice,
  );

  group('issue', () {
    blocTest<DocumentCubit, DocumentState>(
      'issues, fetches and renders the document',
      setUp: () => repository.issueResults.add(_issued),
      build: build,
      act: issueInvoice,
      verify: (cubit) {
        expect(cubit.state.issueStatus, const Status.success());
        expect(cubit.state.renderStatus, const Status.success());
        expect(cubit.state.document, invoice());
        expect(cubit.state.pdf, isNotNull);
        expect(cubit.state.businessId, 'b1');
      },
    );

    blocTest<DocumentCubit, DocumentState>(
      'a retry after a timeout reuses the request id',
      setUp: () => repository.issueResults.addAll([
        const Failure(
          AppException(kind: AppErrorKind.timeout, message: 'slow'),
        ),
        _issued,
      ]),
      build: build,
      act: (cubit) async {
        await issueInvoice(cubit);
        expect(cubit.state.issueStatus.isFailure, isTrue);
        await issueInvoice(cubit);
      },
      verify: (cubit) {
        expect(repository.issueRequestIds, ['request0', 'request0']);
        expect(cubit.state.issueStatus.isSuccess, isTrue);
      },
    );

    blocTest<DocumentCubit, DocumentState>(
      'a refused issue does not reuse its id, a new action gets a new one',
      setUp: () => repository.issueResults.addAll([
        const Failure(
          AppException(
            kind: AppErrorKind.violation,
            message: 'Cancelled transactions cannot issue documents.',
          ),
        ),
        _issued,
        _issued,
      ]),
      build: build,
      act: (cubit) async {
        await issueInvoice(cubit);
        await issueInvoice(cubit);
        await issueInvoice(cubit);
      },
      verify: (_) => expect(repository.issueRequestIds, [
        'request0',
        'request1',
        'request2',
      ]),
    );

    blocTest<DocumentCubit, DocumentState>(
      'offline: issue fails with the offline message and nothing renders',
      setUp: () =>
          repository.issueResults.add(const Failure(AppException.offline())),
      build: build,
      act: issueInvoice,
      expect: () => [
        const DocumentState(businessId: 'b1', issueStatus: Status.loading()),
        DocumentState(
          businessId: 'b1',
          issueStatus: Status.fromException(const AppException.offline()),
        ),
      ],
      verify: (_) => expect(renderer.calls, 0),
    );
  });

  group('render and outputs', () {
    blocTest<DocumentCubit, DocumentState>(
      'opening an issued document renders it locally',
      build: build,
      act: (cubit) => cubit.open(receipt()),
      verify: (cubit) {
        expect(cubit.state.renderStatus.isSuccess, isTrue);
        expect(cubit.state.document?.type, DocumentType.receipt);
      },
    );

    blocTest<DocumentCubit, DocumentState>(
      'a render failure is reported',
      setUp: () => renderer.error = StateError('boom'),
      build: build,
      act: (cubit) => cubit.open(invoice()),
      verify: (cubit) {
        expect(cubit.state.renderStatus.isFailure, isTrue);
        expect(cubit.state.pdf, isNull);
      },
    );

    blocTest<DocumentCubit, DocumentState>(
      'share and print use the document number',
      build: build,
      act: (cubit) async {
        await cubit.open(invoice());
        await cubit.share();
        await cubit.printOrSave();
      },
      verify: (cubit) {
        expect(output.shared, ['INV-2026-0007.pdf']);
        expect(output.printed, ['INV-2026-0007']);
        expect(cubit.state.shareStatus.isSuccess, isTrue);
        expect(cubit.state.printStatus.isSuccess, isTrue);
      },
    );

    blocTest<DocumentCubit, DocumentState>(
      'share does nothing before a render',
      build: build,
      act: (cubit) => cubit.share(),
      expect: () => const <DocumentState>[],
    );
  });

  blocTest<DocumentCubit, DocumentState>(
    'watchTransaction follows the issued documents',
    build: build,
    act: (cubit) async {
      await cubit.watchTransaction('b1', 'tx1');
      repository.watched.add(Success([invoice(), receipt()]));
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      expect(cubit.state.documents, hasLength(2));
      expect(cubit.state.watchStatus.isSuccess, isTrue);
    },
  );
}
