import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:equatable/equatable.dart';

/// The money position of one transaction. All values are minor units.
///
/// The server (`functions/src/ledger.ts`) is the authority and stores these
/// figures; this mirror exists so the client can validate a form and preview
/// the result before calling it. Both are run against the same fixtures in
/// `shared/ledger_cases.json`.
class Balance extends Equatable {
  const Balance({
    required this.total,
    this.paid = 0,
    this.refunded = 0,
    this.credited = 0,
  });

  final int total;
  final int paid;
  final int refunded;
  final int credited;

  /// What the counterparty owes after credits.
  int get payable => total - credited;

  /// Cash that has actually stayed with the receiver.
  int get netPaid => paid - refunded;

  /// The recognised income or expense. A refund reverses part of the sale,
  /// so it comes off here, *and* off [netPaid] — which is why it does not
  /// reopen [outstanding].
  int get effective => total - credited - refunded;

  /// Still to be settled. Never negative while the invariants hold.
  int get outstanding => total - credited - paid;

  /// How much may still be refunded.
  int get refundable => netPaid;

  Balance copyWith({int? total, int? paid, int? refunded, int? credited}) =>
      Balance(
        total: total ?? this.total,
        paid: paid ?? this.paid,
        refunded: refunded ?? this.refunded,
        credited: credited ?? this.credited,
      );

  @override
  List<Object?> get props => <Object?>[total, paid, refunded, credited];

  @override
  String toString() =>
      'Balance(T=$total, P=$paid, R=$refunded, C=$credited, O=$outstanding)';
}

/// Why a financial change was refused. [message] is user-facing.
enum LedgerViolation {
  nonPositiveAmount('Enter an amount greater than zero.'),
  amountTooLarge('That amount is too large.'),
  notConfirmed('Only confirmed transactions can be settled.'),
  notSettleable('This type of transaction does not take payments.'),
  overpayment('That is more than the outstanding balance.'),
  overRefund('That is more than has been paid.'),
  overCredit('A credit cannot exceed the outstanding balance.'),
  totalBelowSettled(
    'The total cannot be less than what has already been paid or credited.',
  ),
  cancelWithMoney(
    'Refund the payments on this transaction before cancelling it.',
  ),
  alreadyCancelled('This transaction is already cancelled.'),
  draftOnly('Only drafts can be changed this way.');

  const LedgerViolation(this.message);
  final String message;
}

/// The ledger's rules, as pure functions. See docs/ARCHITECTURE.md §5.
abstract final class LedgerMath {
  /// Mirrors `Money.maxMinor`; kept local so this file has no imports
  /// beyond the enums and the fixtures can be checked against it directly.
  static const int maxMinor = 10000000000000;

  static PaymentStatus paymentStatusOf(
    Balance balance, {
    required bool settleable,
  }) {
    if (!settleable) return PaymentStatus.notApplicable;
    if (balance.refunded > 0) {
      return balance.refunded >= balance.paid
          ? PaymentStatus.refunded
          : PaymentStatus.partiallyRefunded;
    }
    if (balance.outstanding <= 0) return PaymentStatus.paid;
    if (balance.paid > 0 || balance.credited > 0) {
      return PaymentStatus.partiallyPaid;
    }
    return PaymentStatus.unpaid;
  }

  /// Overdue is a view over the stored state, never stored itself.
  static bool isOverdue({
    required TransactionStatus status,
    required int outstanding,
    required String? dueDate,
    required String today,
  }) =>
      status == TransactionStatus.confirmed &&
      outstanding > 0 &&
      dueDate != null &&
      dueDate.compareTo(today) < 0;

  static LedgerViolation? checkAmount(int amount) {
    if (amount <= 0) return LedgerViolation.nonPositiveAmount;
    if (amount > maxMinor) return LedgerViolation.amountTooLarge;
    return null;
  }

  static LedgerViolation? checkSettlement({
    required SettlementKind kind,
    required Balance balance,
    required int amount,
    required TransactionStatus status,
    required bool settleable,
  }) {
    if (checkAmount(amount) case final violation?) return violation;
    if (status != TransactionStatus.confirmed) {
      return LedgerViolation.notConfirmed;
    }
    if (!settleable) return LedgerViolation.notSettleable;
    return switch (kind) {
      SettlementKind.payment =>
        amount > balance.outstanding ? LedgerViolation.overpayment : null,
      SettlementKind.credit =>
        amount > balance.outstanding ? LedgerViolation.overCredit : null,
      SettlementKind.refund =>
        amount > balance.refundable ? LedgerViolation.overRefund : null,
    };
  }

  /// The balance after a settlement that passed [checkSettlement].
  static Balance apply(Balance balance, SettlementKind kind, int amount) =>
      switch (kind) {
        SettlementKind.payment => balance.copyWith(paid: balance.paid + amount),
        SettlementKind.refund => balance.copyWith(
          refunded: balance.refunded + amount,
        ),
        SettlementKind.credit => balance.copyWith(
          credited: balance.credited + amount,
        ),
      };

  static LedgerViolation? checkTotalEdit(Balance balance, int newTotal) {
    if (checkAmount(newTotal) case final violation?) return violation;
    if (newTotal < balance.paid + balance.credited) {
      return LedgerViolation.totalBelowSettled;
    }
    return null;
  }

  static LedgerViolation? checkCancel(
    Balance balance,
    TransactionStatus status,
  ) {
    if (status == TransactionStatus.cancelled) {
      return LedgerViolation.alreadyCancelled;
    }
    if (balance.netPaid != 0) return LedgerViolation.cancelWithMoney;
    return null;
  }
}
