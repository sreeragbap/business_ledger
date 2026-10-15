import 'dart:async';

import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A brief "done" mark over everything: a circle pops in, a check draws
/// itself, both fade away. For moments worth a beat — a confirm, a payment —
/// not for every save.
void showSuccessCheck(BuildContext context, {required String label}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => SuccessCheck(label: label, onDone: entry.remove),
  );
  overlay.insert(entry);
}

class SuccessCheck extends StatefulWidget {
  const SuccessCheck({required this.label, required this.onDone, super.key});

  final String label;
  final VoidCallback onDone;

  static const Duration duration = Duration(milliseconds: 1100);

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SuccessCheck.duration,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward().whenComplete(widget.onDone));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final pop = reduceMotion
                ? 1.0
                : Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
            final draw = reduceMotion
                ? 1.0
                : ((t - 0.2) / 0.35).clamp(0.0, 1.0);
            final fade = t < 0.75
                ? 1.0
                : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
            return Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: pop,
                child: Semantics(
                  liveRegion: true,
                  label: widget.label,
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.xl.r),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 64.r,
                          child: CustomPaint(
                            painter: _CheckPainter(draw),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        Text(
                          widget.label,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.tint(AppColors.income),
    );
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.67)
      ..lineTo(size.width * 0.73, size.height * 0.36);
    final paint = Paint()
      ..color = AppColors.income
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
