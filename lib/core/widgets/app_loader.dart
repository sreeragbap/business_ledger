import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The app's spinner. Centred by default; prefer a skeleton (`AppSkeleton`)
/// for content that has a known shape.
class AppLoader extends StatelessWidget {
  const AppLoader({this.size, this.color, this.center = true, super.key});

  final double? size;
  final Color? color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 28.r;
    final spinner = SizedBox.square(
      dimension: dimension,
      child: CircularProgressIndicator(
        strokeWidth: dimension / 10,
        strokeCap: StrokeCap.round,
        color: color ?? context.colors.accent,
      ),
    );
    return center ? Center(child: spinner) : spinner;
  }
}
