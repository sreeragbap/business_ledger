import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/widgets/app_status_chip.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:flutter/material.dart';

/// The one chip that best describes a transaction: Draft, Cancelled, or its
/// payment progress with Overdue derived on top. Cross-fades and pops when
/// the status changes (a payment lands, say).
class TransactionStatusChip extends StatelessWidget {
  const TransactionStatusChip({
    required this.transaction,
    required this.today,
    super.key,
  });

  final LedgerTransaction transaction;

  /// `yyyy-MM-dd`.
  final String today;

  static String labelFor(LedgerTransaction tx, String today) {
    if (!tx.isConfirmed) return tx.status.label;
    if (tx.isOverdue(today)) return 'Overdue';
    final payment = tx.paymentStatus;
    if (payment == null || payment == PaymentStatus.notApplicable) {
      return tx.status.label;
    }
    return payment.label;
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final payment = tx.paymentStatus;
    final Widget chip =
        tx.isConfirmed &&
            payment != null &&
            payment != PaymentStatus.notApplicable
        ? AppStatusChip.payment(payment, overdue: tx.isOverdue(today))
        : AppStatusChip.transaction(tx.status);
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(labelFor(tx, today)),
        child: chip,
      ),
    );
  }
}
