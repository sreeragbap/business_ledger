import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_status_chip.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// One transaction in a dashboard list. With [showOutstanding] the figure is
/// what is still owed, labelled as such; otherwise the total.
class TransactionRowTile extends StatelessWidget {
  const TransactionRowTile({
    required this.row,
    required this.currency,
    required this.today,
    this.showOutstanding = false,
    this.onTap,
    super.key,
  });

  final TransactionRow row;
  final Currency currency;

  /// `yyyy-MM-dd`.
  final String today;
  final bool showOutstanding;
  final VoidCallback? onTap;

  static final DateFormat _day = DateFormat('d MMM', 'en_US');

  static String _formatDay(String? key) {
    final parsed = key == null ? null : DateTime.tryParse(key);
    return parsed == null ? '' : _day.format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final inflow = row.direction != Direction.outflow;
    final colour = inflow ? context.colors.income : context.colors.expense;
    final overdue = row.isOverdue(today);
    final amount = showOutstanding ? row.outstandingMinor : row.totalMinor;

    final meta = [
      if (showOutstanding && row.dueDate != null)
        'Due ${_formatDay(row.dueDate)}'
      else if (row.date != null)
        _formatDay(row.date),
      if (row.partyName?.isNotEmpty ?? false) row.partyName!,
    ].join(' · ');

    final Widget chip = switch (row.status) {
      TransactionStatus.confirmed when row.paymentStatus != null =>
        AppStatusChip.payment(row.paymentStatus!, overdue: overdue),
      _ => AppStatusChip.transaction(row.status),
    };

    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
          child: Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: AppColors.tint(colour),
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                ),
                child: Icon(
                  inflow ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: colour,
                  size: 18.r,
                  semanticLabel: inflow ? 'Money in' : 'Money out',
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.xxs.h),
                      Text(
                        meta,
                        style: textTheme.bodySmall?.copyWith(
                          color: overdue ? context.colors.warning : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Money.format(amount, currency),
                    style: AppTextStyles.tabular(
                      textTheme.titleSmall!,
                    ).copyWith(color: colour),
                  ),
                  SizedBox(height: AppSpacing.xxs.h),
                  chip,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
