import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';

/// Contract for issued documents. Blocs depend on this, never on
/// `DocumentService`, so tests inject a stub.
abstract class DocumentRepository {
  const DocumentRepository();

  /// Issues (or returns the existing) invoice, bill or receipt through the
  /// `issueDocument` callable. Requires a connection.
  ///
  /// [requestId] comes from `RequestIds.next()` once per user action and is
  /// reused for every retry of that action.
  Future<AppResult<IssueResult>> issue({
    required String businessId,
    required String transactionId,
    required DocumentType type,
    required String requestId,
    String? settlementId,
  });

  /// Every document issued for a transaction, newest first. Served from the
  /// local cache while offline.
  Stream<AppResult<List<IssuedDocument>>> watchForTransaction(
    String businessId,
    String transactionId,
  );

  Future<AppResult<IssuedDocument>> get(String businessId, String documentId);
}
