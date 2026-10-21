import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
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
    required Color this.color,
    this.icon,
    super.key,
  }) : _colorIn = null;

  /// A colour picked from the active palette when built.
  const AppStatusChip._({
    required this.label,
    required Color Function(AppPalette) this._colorIn,
    this.icon,
    super.key,
  }) : color = null;

  /// Stored payment progress. Pass [overdue] (computed with
  /// `LedgerMath.isOverdue`) to render Overdue on top of it: overdue is never
  /// stored, and wins over unpaid / partially paid.
  factory AppStatusChip.payment(
    PaymentStatus status, {
    bool overdue = false,
    Key? key,
  }) {
    if (overdue) return AppStatusChip.overdue(key: key);
    return AppStatusChip._(
      key: key,
      label: status.label,
      colorIn: (palette) => paymentColor(status, palette),
    );
  }

  factory AppStatusChip.transaction(TransactionStatus status, {Key? key}) =>
      AppStatusChip._(
        key: key,
        label: status.label,
        colorIn: (palette) => transactionColor(status, palette),
        icon: status == TransactionStatus.draft ? Icons.edit_outlined : null,
      );

  const AppStatusChip.overdue({super.key})
    : label = 'Overdue',
      color = null,
      _colorIn = _warning,
      icon = Icons.schedule_rounded;

  final String label;

  /// A fixed colour; `null` when the chip picks one from the palette.
  final Color? color;
  final Color Function(AppPalette)? _colorIn;
  final IconData? icon;

  static Color _warning(AppPalette palette) => palette.warning;

  static Color paymentColor(
    PaymentStatus status,
    AppPalette palette,
  ) => switch (status) {
    PaymentStatus.paid => palette.income,
    PaymentStatus.partiallyPaid => palette.info,
    PaymentStatus.unpaid => palette.textSecondary,
    PaymentStatus.refunded || PaymentStatus.partiallyRefunded => palette.refund,
    PaymentStatus.notApplicable => palette.textTertiary,
  };

  static Color transactionColor(
    TransactionStatus status,
    AppPalette palette,
  ) => switch (status) {
    TransactionStatus.draft => palette.textSecondary,
    TransactionStatus.confirmed => palette.accent,
    TransactionStatus.cancelled => palette.error,
  };

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? _colorIn!(context.colors);
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
