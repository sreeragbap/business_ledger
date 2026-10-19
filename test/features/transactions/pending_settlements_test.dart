import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/pending_settlements.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stub_transaction_repository.dart';
import 'transaction_fixtures.dart';

OutboxEntry settle(
  SettlementKind kind,
  int amount, {
  String id = 'q',
  OutboxStatus status = OutboxStatus.pending,
}) => queuedEntry(
  '$id-${kind.key}-$amount',
  status: status,
  payload: {'kind': kind.key, 'amountMinor': amount},
);

void main() {
  group('payments and credits count queued payments and credits', () {
    // Total 1,000.00, 400.00 paid on the server: 600.00 outstanding.
    final tx = confirmedSale(paid: 40000, status: PaymentStatus.partiallyPaid);

    test('an amount that would overpay after the queued one is refused', () {
      final pending = PendingSettlements.of([
        settle(SettlementKind.payment, 50000),
      ]);
      expect(
        tx.checkSettlement(SettlementKind.payment, 10001, pending: pending),
        LedgerViolation.overpayment,
      );
      expect(
        tx.checkSettlement(SettlementKind.payment, 10000, pending: pending),
        isNull,
      );
      expect(tx.maxSettlement(SettlementKind.payment, pending: pending), 10000);
      // Without the queue the server balance alone would allow it.
      expect(tx.checkSettlement(SettlementKind.payment, 10001), isNull);
    });

    test('queued credits count too, for payments and credits', () {
      final pending = PendingSettlements.of([
        settle(SettlementKind.credit, 20000),
        settle(SettlementKind.payment, 40000, id: 'b'),
      ]);
      expect(
        tx.settlementUnavailableReason(
          SettlementKind.payment,
          pending: pending,
        ),
        'Nothing is outstanding.',
      );
      expect(
        tx.checkSettlement(SettlementKind.credit, 1, pending: pending),
        LedgerViolation.overCredit,
      );
    });

    test('a failed (refused) entry does not count; a syncing one does', () {
      expect(
        PendingSettlements.of([
          settle(SettlementKind.payment, 50000, status: OutboxStatus.failed),
        ]).isEmpty,
        isTrue,
      );
      expect(
        PendingSettlements.of([
          settle(SettlementKind.payment, 50000, status: OutboxStatus.syncing),
        ]).payments,
        50000,
      );
    });

    test('the preview starts from the balance after pending actions', () {
      final pending = PendingSettlements.of([
        settle(SettlementKind.payment, 50000),
      ]);
      final after = tx.previewSettlement(
        SettlementKind.payment,
        10000,
        pending: pending,
      );
      expect(after.paid, 100000);
      expect(after.outstanding, 0);
      expect(tx.balance.paid, 40000, reason: 'server balance untouched');
    });
  });

  group('refunds', () {
    // 500.00 paid, nothing refunded on the server.
    final tx = confirmedSale(paid: 50000, status: PaymentStatus.partiallyPaid);

    test('are limited by what is refundable after queued refunds', () {
      final pending = PendingSettlements.of([
        settle(SettlementKind.refund, 20000),
      ]);
      expect(tx.maxSettlement(SettlementKind.refund, pending: pending), 30000);
      expect(
        tx.checkSettlement(SettlementKind.refund, 30001, pending: pending),
        LedgerViolation.overRefund,
      );
      expect(
        tx.checkSettlement(SettlementKind.refund, 30000, pending: pending),
        isNull,
      );
    });

    test('queued payments are not refundable yet', () {
      final pending = PendingSettlements.of([
        settle(SettlementKind.payment, 50000),
      ]);
      expect(tx.maxSettlement(SettlementKind.refund, pending: pending), 50000);
      final unpaid = confirmedSale();
      expect(
        unpaid.settlementUnavailableReason(
          SettlementKind.refund,
          pending: pending,
        ),
        PendingSettlements.paymentsNotRefundable,
      );
    });
  });

  test('a queued cancel blocks every further settlement', () {
    final pending = PendingSettlements.of([
      queuedEntry('c', kind: OutboxKind.cancel),
    ]);
    for (final kind in SettlementKind.values) {
      expect(
        confirmedSale().settlementUnavailableReason(kind, pending: pending),
        PendingSettlements.cancelQueuedReason,
      );
    }
  });

  group('a draft with a queued confirm', () {
    final draft = draftExpense();

    test('without one, a draft cannot be settled', () {
      expect(
        draft.settlementUnavailableReason(SettlementKind.payment),
        'Confirm the transaction first.',
      );
      expect(
        draft.checkSettlement(SettlementKind.payment, 100),
        LedgerViolation.notConfirmed,
      );
    });

    test('is settled as if confirmed, against the draft total', () {
      final pending = PendingSettlements.of([
        queuedEntry('c', kind: OutboxKind.confirm),
      ]);
      expect(
        draft.settlementUnavailableReason(
          SettlementKind.payment,
          pending: pending,
        ),
        isNull,
      );
      expect(
        draft.checkSettlement(SettlementKind.payment, 5000, pending: pending),
        isNull,
      );
      expect(
        draft.checkSettlement(SettlementKind.payment, 5001, pending: pending),
        LedgerViolation.overpayment,
      );
      expect(
        draft.maxSettlement(SettlementKind.payment, pending: pending),
        5000,
      );
    });

    test('a confirm "as paid" leaves nothing outstanding', () {
      final pending = PendingSettlements.of([
        queuedEntry(
          'c',
          kind: OutboxKind.confirm,
          payload: {'settleNow': true},
        ),
      ]);
      expect(
        draft.settlementUnavailableReason(
          SettlementKind.payment,
          pending: pending,
        ),
        'Nothing is outstanding.',
      );
    });
  });
}
