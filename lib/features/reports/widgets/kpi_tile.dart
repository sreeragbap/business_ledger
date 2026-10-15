import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Counts an amount up (or down) to [minor] whenever it changes.
///
/// The tween runs over integers, so every frame shows a real amount in minor
/// units; it never passes through a fractional value. Holds still when the
/// platform asks for reduced motion.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    required this.minor,
    required this.currency,
    this.style,
    this.compact = false,
    super.key,
  });

  final int minor;
  final Currency currency;
  final TextStyle? style;

  /// `₹1.2M` instead of `₹1,234,567.00`, for tiles. The full amount is
  /// always in the semantics label.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: Money.format(minor, currency),
      excludeSemantics: true,
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: reduceMotion ? minor : 0, end: minor),
        duration: reduceMotion ? Duration.zero : AppMotion.slow * 2,
        curve: AppMotion.standard,
        builder: (context, value, _) => Text(
          compact
              ? Money.compact(value, currency)
              : Money.format(value, currency),
          style: AppTextStyles.tabular(
            style ?? Theme.of(context).textTheme.titleLarge!,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// A headline figure: label, amount, and an optional caption saying exactly
/// what the figure is (income is not cash).
class KpiTile extends StatelessWidget {
  const KpiTile({
    required this.label,
    required this.minor,
    required this.currency,
    required this.colour,
    required this.icon,
    this.caption,
    this.loading = false,
    this.compact = true,
    this.onTap,
    super.key,
  });

  final String label;
  final int minor;
  final Currency currency;
  final Color colour;
  final IconData icon;
  final String? caption;
  final bool loading;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Tooltip(
      message: Money.format(minor, currency),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.xs.r),
                  decoration: BoxDecoration(
                    color: AppColors.tint(colour),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14.r, color: colour),
                ),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),
            if (loading)
              const AppShimmer(child: ShimmerBox(width: 96, height: 22))
            else
              AnimatedMoney(minor: minor, currency: currency, compact: compact),
            if (caption != null) ...[
              SizedBox(height: AppSpacing.xs.h),
              Text(
                caption!,
                style: textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
