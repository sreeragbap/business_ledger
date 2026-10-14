import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppSnackBarKind {
  info(Icons.info_outline_rounded, AppColors.info),
  success(Icons.check_circle_outline_rounded, AppColors.income),
  error(Icons.error_outline_rounded, AppColors.error);

  const AppSnackBarKind(this.icon, this.color);
  final IconData icon;
  final Color color;
}

/// Replaces any visible snack bar with [message].
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarKind kind = AppSnackBarKind.info,
}) {
  if (message.isEmpty) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(kind.icon, color: kind.color, size: 20.r),
            SizedBox(width: AppSpacing.md.w),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
