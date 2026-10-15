import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';

/// The settlement rules for one transaction, as the UI asks them. Every
/// answer comes from `LedgerMath`, the client mirror of the server's checks,
/// so a refusal is explained before the call is made.
extension SettlementRules on LedgerTransaction {
  /// Why [amount] of [kind] would be refused, or `null` when it is fine.
  LedgerViolation? checkSettlement(SettlementKind kind, int amount) =>
      LedgerMath.checkSettlement(
        kind: kind,
        balance: balance,
        amount: amount,
        status: status,
        settleable: isSettleable,
      );

  /// Why [kind] cannot be recorded at all right now, or `null` when it can.
  String? settlementUnavailableReason(SettlementKind kind) {
    if (isRefundEntry) {
      return 'A refund entry changes through its original transaction.';
    }
    if (!type.settleable) return LedgerViolation.notSettleable.message;
    if (isDraft) return 'Confirm the transaction first.';
    if (isCancelled) return 'This transaction is cancelled.';
    return switch (kind) {
      SettlementKind.payment when balance.outstanding <= 0 =>
        'Nothing is outstanding.',
      SettlementKind.credit when balance.outstanding <= 0 =>
        'Nothing is outstanding to credit.',
      SettlementKind.refund when balance.refundable <= 0 =>
        'Nothing has been paid yet, so there is nothing to refund.',
      _ => null,
    };
  }

  bool canSettle(SettlementKind kind) =>
      settlementUnavailableReason(kind) == null;

  /// The most [kind] can be: what is outstanding, or for a refund what has
  /// been paid and not yet refunded.
  int maxSettlement(SettlementKind kind) => switch (kind) {
    SettlementKind.refund => balance.refundable,
    SettlementKind.payment || SettlementKind.credit => balance.outstanding,
  };

  /// The balance after [amount] of [kind]; only meaningful when
  /// [checkSettlement] passed.
  Balance previewSettlement(SettlementKind kind, int amount) =>
      LedgerMath.apply(balance, kind, amount);

  PaymentStatus paymentStatusFor(Balance next) =>
      LedgerMath.paymentStatusOf(next, settleable: type.settleable);

  /// Why this entry cannot be cancelled, or `null` when it can.
  String? cancelBlockedReason() {
    if (isRefundEntry) {
      return 'A refund entry cannot be cancelled on its own.';
    }
    if (isDraft) return 'Drafts are deleted, not cancelled.';
    return LedgerMath.checkCancel(balance, status)?.message;
  }
}
