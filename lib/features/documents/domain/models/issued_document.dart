import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/documents/domain/models/document_snapshot.dart';
import 'package:business_ledger/features/documents/domain/models/json_reader.dart';
import 'package:equatable/equatable.dart';

/// `businesses/{bid}/documents/{docId}`: an invoice, bill or receipt with
/// its gap-free number and the snapshot it is rendered from.
class IssuedDocument extends Equatable {
  const IssuedDocument({
    required this.id,
    required this.type,
    required this.number,
    required this.transactionId,
    required this.snapshot,
    this.settlementId,
    this.issuedAt,
    this.issuedBy,
    this.voided = false,
    this.storagePath,
  });

  factory IssuedDocument.fromMap(String id, Map<String, dynamic> map) {
    final json = JsonReader(map, 'documents/$id');
    final typeKey = json.string('type');
    final type = DocumentType.values.where((t) => t.key == typeKey);
    if (type.isEmpty) {
      throw FormatException('documents/$id.type: unknown "$typeKey"');
    }
    return IssuedDocument(
      id: id,
      type: type.first,
      number: json.string('number'),
      transactionId: json.string('transactionId'),
      settlementId: json.optionalString('settlementId'),
      snapshot: DocumentSnapshot.read(json.map('snapshot')),
      issuedAt: json.timestamp('issuedAt'),
      issuedBy: json.optionalString('issuedBy'),
      voided: json.boolean('voided'),
      storagePath: json.optionalString('storagePath'),
    );
  }

  /// The id the server derives for a document, so the same request always
  /// lands on the same record (`issueDocument`).
  static String idFor({
    required DocumentType type,
    required String transactionId,
    String? settlementId,
  }) => '${type.key}-$transactionId-${settlementId ?? 'main'}';

  final String id;
  final DocumentType type;

  /// `PREFIX-YYYY-NNNN`.
  final String number;
  final String transactionId;
  final String? settlementId;
  final DocumentSnapshot snapshot;

  /// `null` while the server timestamp is still pending locally.
  final DateTime? issuedAt;
  final String? issuedBy;

  /// Set when the transaction was cancelled. A voided document still renders,
  /// with a VOID watermark.
  final bool voided;

  /// Where the uploaded PDF lives, once one has been attached.
  final String? storagePath;

  bool get isUploaded => storagePath != null && storagePath!.isNotEmpty;

  /// A file name that is safe on every platform: `INV-2026-0001.pdf`.
  String get fileName =>
      '${number.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_')}.pdf';

  @override
  List<Object?> get props => [
    id,
    type,
    number,
    transactionId,
    settlementId,
    snapshot,
    issuedAt,
    issuedBy,
    voided,
    storagePath,
  ];
}

/// What `issueDocument` returns.
class IssueResult extends Equatable {
  const IssueResult({
    required this.documentId,
    required this.number,
    required this.created,
  });

  factory IssueResult.fromMap(Map<String, dynamic> map) {
    final json = JsonReader(map, 'issueDocument');
    return IssueResult(
      documentId: json.string('documentId'),
      number: json.string('number'),
      created: json.boolean('created'),
    );
  }

  final String documentId;
  final String number;

  /// `false` when the document already existed and was returned as is.
  final bool created;

  @override
  List<Object?> get props => [documentId, number, created];
}
