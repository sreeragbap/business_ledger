import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/features/reports/domain/logic/report_aggregator.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Ranked rows with a bar proportional to each share of the total.
class BreakdownList extends StatelessWidget {
  const BreakdownList({
    required this.entries,
    required this.currency,
    required this.colour,
    this.maxRows = 6,
    this.emptyText = 'Nothing recorded in this period.',
    this.onTap,
    super.key,
  });

  final List<BreakdownEntry> entries;
  final Currency currency;
  final Color colour;
  final int maxRows;
  final String emptyText;

  /// Filters the report to the tapped entry, when given.
  final ValueChanged<BreakdownEntry>? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
        child: Text(emptyText, style: textTheme.bodyMedium),
      );
    }
    final shown = entries.take(maxRows).toList();
    final rest = entries.skip(maxRows).toList();
    return Column(
      children: [
        for (final entry in shown)
          _Row(
            entry: entry,
            currency: currency,
            colour: colour,
            onTap: onTap == null ? null : () => onTap!(entry),
          ),
        if (rest.isNotEmpty)
          _Row(
            entry: BreakdownEntry(
              id: '',
              label: '${rest.length} more',
              amountMinor: rest.fold(0, (s, e) => s + e.amountMinor),
              shareBasisPoints: rest.fold(
                0,
                (s, e) => s + e.shareBasisPoints,
              ),
            ),
            currency: currency,
            colour: AppColors.textTertiary,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.currency,
    required this.colour,
    this.onTap,
  });

  final BreakdownEntry entry;
  final Currency currency;
  final Color colour;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amount = Money.format(entry.amountMinor, currency);
    final fraction = entry.shareBasisPoints / ReportAggregator.fullShare;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: '${entry.label}: $amount, ${entry.sharePercent}',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.label,
                      style: textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Text(
                    amount,
                    style: AppTextStyles.tabular(textTheme.titleSmall!),
                  ),
                  SizedBox(
                    width: 52.w,
                    child: Text(
                      entry.sharePercent,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.tabular(textTheme.labelMedium!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs.h),
              ClipRRect(
                borderRadius: AppRadius.chip,
                child: SizedBox(
                  height: 6.h,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: reduceMotion ? fraction : 0,
                      end: fraction,
                    ),
                    duration: reduceMotion ? Duration.zero : AppMotion.slow,
                    curve: AppMotion.standard,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      color: colour,
                      backgroundColor: AppColors.surfaceRaised,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
