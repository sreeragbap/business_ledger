import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/features/documents/domain/models/document_layout_data.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:equatable/equatable.dart';

/// A recorded settlement, as the documents sheet needs it.
class DocumentPaymentRef extends Equatable {
  const DocumentPaymentRef({
    required this.settlementId,
    required this.kind,
    required this.amountMinor,
    required this.date,
    this.voided = false,
  });

  final String settlementId;
  final SettlementKind kind;
  final int amountMinor;

  /// `yyyy-MM-dd`.
  final String date;
  final bool voided;

  @override
  List<Object?> get props => [settlementId, kind, amountMinor, date, voided];
}

/// The transaction the documents sheet is opened for. A deliberately small
/// read model, so this feature does not depend on the transactions feature.
class DocumentSubject extends Equatable {
  const DocumentSubject({
    required this.businessId,
    required this.transactionId,
    required this.type,
    required this.status,
    required this.currency,
    this.payments = const [],
  });

  final String businessId;
  final String transactionId;
  final TransactionType type;
  final TransactionStatus status;
  final Currency currency;
  final List<DocumentPaymentRef> payments;

  @override
  List<Object?> get props => [
    businessId,
    transactionId,
    type,
    status,
    currency,
    payments,
  ];
}

/// One row of the documents sheet: issue or open an invoice, bill or receipt.
class DocumentAction extends Equatable {
  const DocumentAction({
    required this.type,
    required this.title,
    required this.subtitle,
    this.settlementId,
    this.existing,
    this.disabledReason,
  });

  final DocumentType type;

  /// Set for receipts.
  final String? settlementId;
  final String title;
  final String subtitle;

  /// The document already issued for this action, if any. Opening it works
  /// offline; issuing does not (it is never queued).
  final IssuedDocument? existing;

  /// Why the action cannot be taken. `null` when it can.
  final String? disabledReason;

  bool get enabled => disabledReason == null;
  bool get isIssued => existing != null;

  @override
  List<Object?> get props => [
    type,
    settlementId,
    title,
    subtitle,
    existing,
    disabledReason,
  ];
}

/// Which documents a transaction can have, and whether each can be issued
/// or opened right now. Pure; mirrors the server's checks in
/// `issueDocument` so the sheet explains a refusal before the call is made.
abstract final class DocumentActions {
  static const String draftReason =
      'Confirm the transaction before issuing a document.';
  static const String cancelledReason =
      'Cancelled transactions cannot issue documents.';

  /// Offline, or Cloud sync off: numbering must come from the server.
  static const String offlineReason =
      'Needs a connection and sync turned on. Issuing a document takes the '
      'next number from the server.';
  static const String noDocumentReason =
      "This type of transaction doesn't have an invoice or bill.";

  static List<DocumentAction> forSubject(
    DocumentSubject subject, {
    required List<IssuedDocument> issued,
    required bool online,
  }) {
    IssuedDocument? find(DocumentType type, String? settlementId) {
      final id = IssuedDocument.idFor(
        type: type,
        transactionId: subject.transactionId,
        settlementId: settlementId,
      );
      for (final document in issued) {
        if (document.id == id) return document;
      }
      return null;
    }

    String? reasonFor(IssuedDocument? existing) {
      // An issued document can always be opened: it renders from its cached
      // snapshot, with a VOID mark when the transaction was cancelled.
      if (existing != null) return null;
      return switch (subject.status) {
        TransactionStatus.draft => draftReason,
        TransactionStatus.cancelled => cancelledReason,
        TransactionStatus.confirmed => online ? null : offlineReason,
      };
    }

    String subtitleFor(IssuedDocument? existing, String fallback) {
      if (existing == null) return fallback;
      return existing.voided
          ? '${existing.number} · Void'
          : '${existing.number} · Issued';
    }

    final actions = <DocumentAction>[];
    final mainType = subject.type.documentType;
    if (mainType != null) {
      final existing = find(mainType, null);
      actions.add(
        DocumentAction(
          type: mainType,
          title: existing == null
              ? 'Issue ${mainType.label.toLowerCase()}'
              : 'View ${mainType.label.toLowerCase()}',
          subtitle: subtitleFor(
            existing,
            mainType == DocumentType.invoice
                ? 'For the customer: what they owe'
                : 'For your records: what you owe',
          ),
          existing: existing,
          disabledReason: reasonFor(existing),
        ),
      );
    }

    final payments = subject.payments.where(
      (payment) => payment.kind == SettlementKind.payment && !payment.voided,
    );
    for (final payment in payments) {
      final existing = find(DocumentType.receipt, payment.settlementId);
      final amount = Money.format(payment.amountMinor, subject.currency);
      final day = DocumentLayoutData.formatDay(payment.date);
      actions.add(
        DocumentAction(
          type: DocumentType.receipt,
          settlementId: payment.settlementId,
          title: existing == null
              ? 'Issue receipt for $amount'
              : 'View receipt for $amount',
          subtitle: subtitleFor(existing, 'Payment on $day'),
          existing: existing,
          disabledReason: reasonFor(existing),
        ),
      );
    }
    return actions;
  }

  /// Shown when [forSubject] returns nothing.
  static String emptyMessage(DocumentSubject subject) =>
      subject.type.documentType == null
      ? '$noDocumentReason Receipts appear here once a payment is recorded.'
      : 'Receipts appear here once a payment is recorded.';
}
