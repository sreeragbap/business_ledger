import 'dart:ui';

import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/features/receipt_scan/logic/receipt_scan_cubit/receipt_scan_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Covers the form while a receipt is read: a blurred backdrop and a card
/// with a receipt that a light beam sweeps over. The title moves from
/// reading to "understanding with AI" as the scan advances.
class ReceiptReadingOverlay extends StatelessWidget {
  const ReceiptReadingOverlay({required this.phase, super.key});

  final ReceiptScanPhase phase;

  @override
  Widget build(BuildContext context) {
    final visible =
        phase == ReceiptScanPhase.reading ||
        phase == ReceiptScanPhase.understanding;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.standard,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: visible
            ? _Backdrop(
                key: const ValueKey('reading'),
                understanding: phase == ReceiptScanPhase.understanding,
              )
            : const SizedBox.shrink(key: ValueKey('hidden')),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.understanding, super.key});

  final bool understanding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      label: understanding
          ? 'Understanding the receipt'
          : 'Reading the receipt',
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: ColoredBox(
          color: colors.scrim.withValues(alpha: 0.45),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1),
              duration: AppMotion.slow,
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 272.w,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxl.w,
                  AppSpacing.xxl.h,
                  AppSpacing.xxl.w,
                  AppSpacing.xl.h,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScanningReceipt(understanding: understanding),
                    SizedBox(height: AppSpacing.xl.h),
                    AnimatedSwitcher(
                      duration: AppMotion.medium,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(understanding),
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (understanding) ...[
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18.r,
                                  color: colors.accent,
                                ),
                                SizedBox(width: AppSpacing.xs.w),
                              ],
                              Text(
                                understanding
                                    ? 'Understanding with AI…'
                                    : 'Reading the receipt…',
                                style: textTheme.titleMedium,
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs.h),
                          Text(
                            understanding
                                ? 'Picking the amount, date, shop and '
                                      'category'
                                : 'Finding the text on the page',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: colors.accent,
                        backgroundColor: colors.accentMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small receipt — rows, a total with the double rule, like the app icon
/// — with a glowing beam sweeping up and down. While AI reads, the rows
/// take the accent colour one by one.
class _ScanningReceipt extends StatefulWidget {
  const _ScanningReceipt({required this.understanding});

  final bool understanding;

  @override
  State<_ScanningReceipt> createState() => _ScanningReceiptState();
}

class _ScanningReceiptState extends State<_ScanningReceipt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _beam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final width = 120.r;
    final height = 150.r;
    final rowColour = widget.understanding
        ? colors.accent.withValues(alpha: 0.55)
        : colors.borderStrong;
    final inkColour = widget.understanding
        ? colors.accent
        : colors.textTertiary;

    Widget bar(double widthFactor, Color colour, {double thickness = 7}) =>
        AnimatedContainer(
          duration: AppMotion.slow,
          curve: AppMotion.standard,
          width: width * widthFactor,
          height: thickness.r,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );

    Widget row(double left, double right, Color colour) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [bar(left, colour), bar(right, colour)],
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14.r,
                vertical: 18.r,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: bar(0.45, inkColour, thickness: 9),
                  ),
                  const Spacer(),
                  row(0.32, 0.18, rowColour),
                  SizedBox(height: 10.r),
                  row(0.26, 0.2, rowColour),
                  SizedBox(height: 10.r),
                  row(0.3, 0.16, rowColour),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        bar(0.34, inkColour, thickness: 9),
                        SizedBox(height: 5.r),
                        bar(0.34, inkColour, thickness: 3),
                        SizedBox(height: 3.r),
                        bar(0.34, inkColour, thickness: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _beam,
            builder: (context, _) {
              final t = Curves.easeInOutSine.transform(_beam.value);
              return Positioned(
                left: -6.r,
                right: -6.r,
                top: t * (height - 3),
                child: _Beam(
                  colour: colors.accent,
                  goingDown: _beam.status == AnimationStatus.forward,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The scan line with a soft trail behind the way it moves.
class _Beam extends StatelessWidget {
  const _Beam({required this.colour, required this.goingDown});

  final Color colour;
  final bool goingDown;

  @override
  Widget build(BuildContext context) {
    final trail = Container(
      height: 22.r,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: goingDown ? Alignment.bottomCenter : Alignment.topCenter,
          end: goingDown ? Alignment.topCenter : Alignment.bottomCenter,
          colors: [colour.withValues(alpha: 0.28), colour.withValues(alpha: 0)],
        ),
      ),
    );
    final line = Container(
      height: 3,
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(color: colour.withValues(alpha: 0.6), blurRadius: 10),
        ],
      ),
    );
    // The trail sits on the side the beam came from.
    return Transform.translate(
      offset: Offset(0, goingDown ? -22.r : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: goingDown ? [trail, line] : [line, trail],
      ),
    );
  }
}
