/// The ledger's vocabulary. Wire keys ([key]) are shared with Cloud
/// Functions (`functions/src/ledger.ts`) and the security rules: renaming
/// one is a data migration, not a refactor.
library;

/// Which way money moves, from the business's point of view.
enum Direction {
  inflow('in'),
  outflow('out');

  const Direction(this.key);
  final String key;

  static Direction fromKey(String? key) =>
      key == outflow.key ? outflow : inflow;
}

enum DocumentType {
  invoice('invoice', 'Invoice'),
  bill('bill', 'Bill'),
  receipt('receipt', 'Receipt');

  const DocumentType(this.key, this.label);
  final String key;
  final String label;

  static DocumentType fromKey(String? key) =>
      values.firstWhere((type) => type.key == key, orElse: () => invoice);
}

enum TransactionType {
  income('income', 'Income', Direction.inflow, settleable: true),
  sale('sale', 'Sale', Direction.inflow, settleable: true),
  expense('expense', 'Expense', Direction.outflow, settleable: true),
  purchase('purchase', 'Purchase', Direction.outflow, settleable: true),

  /// A standalone money movement: an advance, a transfer, a loan repayment.
  /// Its direction is chosen per entry, and it is settled on confirm.
  payment('payment', 'Payment', null, settleable: true),

  /// A correction to income or expense with no cash side.
  adjustment('adjustment', 'Adjustment', null, settleable: false),

  /// Created by the server alongside a refund settlement, linked to the
  /// original. Never created from the "new transaction" form.
  refund('refund', 'Refund', null, settleable: false);

  const TransactionType(
    this.key,
    this.label,
    this.fixedDirection, {
    required this.settleable,
  });

  final String key;
  final String label;

  /// `null` when the user picks the direction for each entry.
  final Direction? fixedDirection;

  /// Whether payments, refunds and credits can be recorded against it.
  final bool settleable;

  bool get isCreatable => this != refund;

  /// The document this type produces, if any. Receipts come from
  /// settlements, not from the transaction itself.
  DocumentType? get documentType => switch (this) {
    sale || income => DocumentType.invoice,
    purchase || expense => DocumentType.bill,
    payment || adjustment || refund => null,
  };

  static TransactionType fromKey(String? key) =>
      values.firstWhere((type) => type.key == key, orElse: () => expense);
}

enum TransactionStatus {
  /// Incomplete or unconfirmed. Excluded from every financial figure.
  draft('draft', 'Draft'),
  confirmed('confirmed', 'Confirmed'),

  /// Voided. Kept in history, excluded from active figures.
  cancelled('cancelled', 'Cancelled');

  const TransactionStatus(this.key, this.label);
  final String key;
  final String label;

  static TransactionStatus fromKey(String? key) =>
      values.firstWhere((status) => status.key == key, orElse: () => draft);
}

/// Stored payment progress. Overdue is deliberately absent: it depends on
/// today's date, so it is derived at read time, see `LedgerMath.isOverdue`.
enum PaymentStatus {
  unpaid('unpaid', 'Unpaid'),
  partiallyPaid('partiallyPaid', 'Partially paid'),
  paid('paid', 'Paid'),
  partiallyRefunded('partiallyRefunded', 'Partially refunded'),
  refunded('refunded', 'Refunded'),
  notApplicable('notApplicable', '—');

  const PaymentStatus(this.key, this.label);
  final String key;
  final String label;

  static PaymentStatus fromKey(String? key) =>
      values.firstWhere((status) => status.key == key, orElse: () => unpaid);
}

enum SettlementKind {
  payment('payment', 'Payment'),
  refund('refund', 'Refund'),

  /// A discount or credit note: reduces what is owed without cash moving.
  credit('credit', 'Credit');

  const SettlementKind(this.key, this.label);
  final String key;
  final String label;

  static SettlementKind fromKey(String? key) =>
      values.firstWhere((kind) => kind.key == key, orElse: () => payment);
}
