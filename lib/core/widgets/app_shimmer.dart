import 'dart:async';

import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Sweeps a soft highlight across [child]'s opaque pixels. Wrap a layout of
/// [ShimmerBox]es to build a skeleton.
///
/// Honours the platform's reduce-motion setting by holding still.
class AppShimmer extends StatefulWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  static const Duration oneSweep = Duration(milliseconds: 1400);

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppShimmer.oneSweep,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            AppColors.shimmerBase,
            AppColors.shimmerHighlight,
            AppColors.shimmerBase,
          ],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlidingGradient(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _SlidingGradient extends GradientTransform {
  const _SlidingGradient(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final offset = bounds.width * (progress * 2 - 1);
    return Matrix4.translationValues(offset, 0, 0);
  }
}

/// One placeholder block inside an [AppShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    required this.height,
    this.width = double.infinity,
    this.radius,
    super.key,
  });

  /// Design units, scaled here. `double.infinity` fills the row.
  final double width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.isFinite ? width.w : width,
      height: height.h,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular((radius ?? AppRadius.sm).r),
      ),
    );
  }
}

/// A generic list skeleton: [rows] card-shaped rows with a title and a
/// trailing figure. Good enough until a screen draws its own.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({this.rows = 6, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.screenHorizontal.w),
        itemCount: rows,
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
        itemBuilder: (_, _) => Row(
          children: [
            const ShimmerBox(width: 40, height: 40, radius: AppRadius.md),
            SizedBox(width: AppSpacing.md.w),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160, height: 14),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerBox(width: 96, height: 12),
                ],
              ),
            ),
            const ShimmerBox(width: 72, height: 16),
          ],
        ),
      ),
    );
  }
}
