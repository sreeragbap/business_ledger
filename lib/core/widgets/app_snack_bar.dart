import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppSnackBarKind {
  info(Icons.info_outline_rounded),
  success(Icons.check_circle_outline_rounded),
  error(Icons.error_outline_rounded);

  const AppSnackBarKind(this.icon);
  final IconData icon;

  Color colorIn(AppPalette palette) => switch (this) {
    info => palette.info,
    success => palette.income,
    error => palette.error,
  };
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
            Icon(kind.icon, color: kind.colorIn(context.colors), size: 20.r),
            SizedBox(width: AppSpacing.md.w),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
