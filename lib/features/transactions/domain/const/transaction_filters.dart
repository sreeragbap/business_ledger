import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:flutter/material.dart';

/// The payment-status filter of the transactions list. Mostly the stored
/// [PaymentStatus], plus two views computed over it:
///
/// * [open]: confirmed with money still outstanding (`isOpen`);
/// * [overdue]: open and past its due date. Never stored
///   (ARCHITECTURE §5), so it is a query on `isOpen` + `dueDate < today`.
enum PaymentFilter {
  unpaid('Unpaid', PaymentStatus.unpaid),
  partiallyPaid('Partially paid', PaymentStatus.partiallyPaid),
  paid('Paid', PaymentStatus.paid),
  partiallyRefunded('Partially refunded', PaymentStatus.partiallyRefunded),
  refunded('Refunded', PaymentStatus.refunded),
  open('Outstanding', null),
  overdue('Overdue', null);

  const PaymentFilter(this.label, this.stored);

  final String label;

  /// The stored status this filter equals, or `null` for a derived view.
  final PaymentStatus? stored;

  bool get isDerived => stored == null;
}

/// How the list is ordered. Only the date orders can come straight from
/// Firestore (the indexes are on `dateTs`); amount orders are applied on the
/// device to the entries loaded so far.
enum TransactionSort {
  dateDesc('Newest first', Icons.arrow_downward_rounded),
  dateAsc('Oldest first', Icons.arrow_upward_rounded),
  amountDesc('Largest amount', Icons.trending_down_rounded),
  amountAsc('Smallest amount', Icons.trending_up_rounded);

  const TransactionSort(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get byDate => this == dateDesc || this == dateAsc;
}

/// Suggestions for the payment method field. Free text is stored, so a
/// business can type its own.
abstract final class PaymentMethods {
  static const List<String> common = [
    'Cash',
    'Bank transfer',
    'UPI',
    'Card',
    'Cheque',
  ];

  /// `text(40)` in `functions/src/schemas.ts`.
  static const int maxLength = 40;
}
