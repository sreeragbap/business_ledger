import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:equatable/equatable.dart';

/// What this user's queued (not yet applied) actions on one transaction will
/// do to its balance, for **client pre-validation only**: a new settlement is
/// checked as if they had already been applied, so two offline payments
/// cannot together overpay. The balance shown on screen stays the server's.
///
/// Only entries still on their way count (pending or syncing); a failed one
/// is not going to apply unless the user retries it.
class PendingSettlements extends Equatable {
  const PendingSettlements({
    this.payments = 0,
    this.credits = 0,
    this.refunds = 0,
    this.cancelQueued = false,
    this.confirmQueued = false,
    this.confirmSettles = false,
  });

  factory PendingSettlements.of(Iterable<OutboxEntry> entries) {
    var payments = 0;
    var credits = 0;
    var refunds = 0;
    var cancel = false;
    var confirm = false;
    var settles = false;
    for (final entry in entries) {
      if (entry.isFailed) continue;
      switch (entry.kind) {
        case OutboxKind.settle:
          final amount = (entry.payload['amountMinor'] as num?)?.toInt() ?? 0;
          switch (SettlementKind.fromKey(entry.payload['kind'] as String?)) {
            case SettlementKind.payment:
              payments += amount;
            case SettlementKind.credit:
              credits += amount;
            case SettlementKind.refund:
              refunds += amount;
          }
        case OutboxKind.cancel:
          cancel = true;
        case OutboxKind.confirm:
          confirm = true;
          settles = settles || entry.payload['settleNow'] == true;
        case OutboxKind.edit || OutboxKind.upsert || OutboxKind.update:
          // No money effect (a draft's own row write, or an edit).
          break;
      }
    }
    return PendingSettlements(
      payments: payments,
      credits: credits,
      refunds: refunds,
      cancelQueued: cancel,
      confirmQueued: confirm,
      confirmSettles: settles,
    );
  }

  static const PendingSettlements none = PendingSettlements();

  /// Queued payment, credit and refund amounts (minor units).
  final int payments;
  final int credits;
  final int refunds;

  /// A cancel is waiting: nothing more can be recorded.
  final bool cancelQueued;

  /// A confirm is waiting: the draft is treated as confirmed.
  final bool confirmQueued;

  /// That confirm also records the full amount as paid ("confirm as paid").
  final bool confirmSettles;

  bool get isEmpty => this == none;

  static const String cancelQueuedReason =
      'A cancel is waiting to sync, so no more money can be recorded.';

  static const String paymentsNotRefundable =
      'Payments waiting to sync can be refunded once they are applied.';

  /// The status checks run against: a draft with a queued confirm counts as
  /// confirmed.
  TransactionStatus statusFor(TransactionStatus status) =>
      confirmQueued && status == TransactionStatus.draft
      ? TransactionStatus.confirmed
      : status;

  /// Every queued action applied: what payments and credits are checked
  /// against, and what the preview shows ("after pending actions").
  Balance projected(Balance server) {
    final settled = confirmSettles && server.paid == 0
        ? server.total - server.credited
        : 0;
    return server.copyWith(
      paid: server.paid + payments + settled,
      credited: server.credited + credits,
      refunded: server.refunded + refunds,
    );
  }

  /// What a new refund is checked against: queued refunds and credits
  /// count, queued payments do not (they are not refundable until applied).
  Balance forRefunds(Balance server) => server.copyWith(
    credited: server.credited + credits,
    refunded: server.refunded + refunds,
  );

  /// The balance [kind] is checked against.
  Balance forKind(SettlementKind kind, Balance server) =>
      kind == SettlementKind.refund ? forRefunds(server) : projected(server);

  @override
  List<Object?> get props => [
    payments,
    credits,
    refunds,
    cancelQueued,
    confirmQueued,
    confirmSettles,
  ];
}
