import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/pending_settlements.dart';

/// The settlement rules for one transaction, as the UI asks them. Every
/// answer comes from `LedgerMath`, the client mirror of the server's checks,
/// so a refusal is explained before the call is made.
///
/// `pending` is what this user's queued actions on the transaction will do
/// (see [PendingSettlements]): new settlements are checked as if they had
/// already applied.
extension SettlementRules on LedgerTransaction {
  /// Why [amount] of [kind] would be refused, or `null` when it is fine.
  LedgerViolation? checkSettlement(
    SettlementKind kind,
    int amount, {
    PendingSettlements pending = PendingSettlements.none,
  }) => LedgerMath.checkSettlement(
    kind: kind,
    balance: pending.forKind(kind, balance),
    amount: amount,
    status: pending.statusFor(status),
    settleable: isSettleable,
  );

  /// Why [kind] cannot be recorded at all right now, or `null` when it can.
  String? settlementUnavailableReason(
    SettlementKind kind, {
    PendingSettlements pending = PendingSettlements.none,
  }) {
    if (isRefundEntry) {
      return 'A refund entry changes through its original transaction.';
    }
    if (!type.settleable) return LedgerViolation.notSettleable.message;
    if (isCancelled) return 'This transaction is cancelled.';
    if (pending.cancelQueued) return PendingSettlements.cancelQueuedReason;
    if (isDraft && !pending.confirmQueued) {
      return 'Confirm the transaction first.';
    }
    final checked = pending.forKind(kind, balance);
    return switch (kind) {
      SettlementKind.payment when checked.outstanding <= 0 =>
        'Nothing is outstanding.',
      SettlementKind.credit when checked.outstanding <= 0 =>
        'Nothing is outstanding to credit.',
      SettlementKind.refund when checked.refundable <= 0 =>
        pending.payments > 0
            ? PendingSettlements.paymentsNotRefundable
            : 'Nothing has been paid yet, so there is nothing to refund.',
      _ => null,
    };
  }

  bool canSettle(
    SettlementKind kind, {
    PendingSettlements pending = PendingSettlements.none,
  }) => settlementUnavailableReason(kind, pending: pending) == null;

  /// The most [kind] can be: what is outstanding, or for a refund what has
  /// been paid and not yet refunded, after the [pending] actions.
  int maxSettlement(
    SettlementKind kind, {
    PendingSettlements pending = PendingSettlements.none,
  }) {
    final checked = pending.forKind(kind, balance);
    return switch (kind) {
      SettlementKind.refund => checked.refundable,
      SettlementKind.payment || SettlementKind.credit => checked.outstanding,
    };
  }

  /// The balance after the [pending] actions and then [amount] of [kind];
  /// only meaningful when [checkSettlement] passed.
  Balance previewSettlement(
    SettlementKind kind,
    int amount, {
    PendingSettlements pending = PendingSettlements.none,
  }) => LedgerMath.apply(pending.projected(balance), kind, amount);

  PaymentStatus paymentStatusFor(Balance next) =>
      LedgerMath.paymentStatusOf(next, settleable: type.settleable);

  /// Why this entry cannot be cancelled, or `null` when it can. Queued
  /// payments count: once applied they would hold money.
  String? cancelBlockedReason({
    PendingSettlements pending = PendingSettlements.none,
  }) {
    if (isRefundEntry) {
      return 'A refund entry cannot be cancelled on its own.';
    }
    if (isDraft) return 'Drafts are deleted, not cancelled.';
    return LedgerMath.checkCancel(pending.projected(balance), status)?.message;
  }
}
