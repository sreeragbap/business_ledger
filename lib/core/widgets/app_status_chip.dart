import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A small status label: the colour's tint behind its own text.
///
/// Use the named constructors for ledger statuses so a status is the same
/// colour everywhere it appears.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  /// Stored payment progress. Pass [overdue] (computed with
  /// `LedgerMath.isOverdue`) to render Overdue on top of it: overdue is never
  /// stored, and wins over unpaid / partially paid.
  factory AppStatusChip.payment(
    PaymentStatus status, {
    bool overdue = false,
    Key? key,
  }) {
    if (overdue) return AppStatusChip.overdue(key: key);
    return AppStatusChip(
      key: key,
      label: status.label,
      color: paymentColor(status),
    );
  }

  factory AppStatusChip.transaction(TransactionStatus status, {Key? key}) =>
      AppStatusChip(
        key: key,
        label: status.label,
        color: transactionColor(status),
        icon: status == TransactionStatus.draft ? Icons.edit_outlined : null,
      );

  const AppStatusChip.overdue({super.key})
    : label = 'Overdue',
      color = AppColors.warning,
      icon = Icons.schedule_rounded;

  final String label;
  final Color color;
  final IconData? icon;

  static Color paymentColor(PaymentStatus status) => switch (status) {
    PaymentStatus.paid => AppColors.income,
    PaymentStatus.partiallyPaid => AppColors.info,
    PaymentStatus.unpaid => AppColors.textSecondary,
    PaymentStatus.refunded ||
    PaymentStatus.partiallyRefunded => AppColors.refund,
    PaymentStatus.notApplicable => AppColors.textTertiary,
  };

  static Color transactionColor(TransactionStatus status) => switch (status) {
    TransactionStatus.draft => AppColors.textSecondary,
    TransactionStatus.confirmed => AppColors.accent,
    TransactionStatus.cancelled => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.xxs.h + 1,
        ),
        decoration: BoxDecoration(
          color: AppColors.tint(color),
          borderRadius: AppRadius.chip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12.r, color: color),
              SizedBox(width: AppSpacing.xs.w),
            ],
            Text(label, style: style),
          ],
        ),
      ),
    );
  }
}
