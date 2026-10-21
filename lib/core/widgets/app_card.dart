import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A bordered surface panel. Tappable when [onTap] is given, with the ripple
/// clipped to the card's corners.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Defaults to [AppSpacing.lg] on every side.
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = AppRadius.card;
    return Material(
      color: color ?? context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: AppSpacing.lg.w,
                vertical: AppSpacing.lg.h,
              ),
          child: child,
        ),
      ),
    );
  }
}
