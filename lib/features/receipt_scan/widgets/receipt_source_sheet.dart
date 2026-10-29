import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Asks where the receipt comes from. `null` when dismissed.
Future<ReceiptSource?> showReceiptSourceSheet(
  BuildContext context, {
  required bool cameraAvailable,
}) => showAppBottomSheet<ReceiptSource>(
  context: context,
  title: 'Scan a receipt',
  child: _SourceList(cameraAvailable: cameraAvailable),
);

class _SourceList extends StatelessWidget {
  const _SourceList({required this.cameraAvailable});

  final bool cameraAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Rise(
          index: 0,
          child: _SourceTile(
            icon: Icons.document_scanner_outlined,
            title: 'Scan with camera',
            subtitle: cameraAvailable
                ? 'Finds the edges and straightens the receipt'
                : 'Not available on this device',
            onTap: cameraAvailable
                ? () => Navigator.of(context).pop(ReceiptSource.camera)
                : null,
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        _Rise(
          index: 1,
          child: _SourceTile(
            icon: Icons.photo_library_outlined,
            title: 'Choose a photo',
            subtitle: 'A receipt you already photographed',
            onTap: () => Navigator.of(context).pop(ReceiptSource.photos),
          ),
        ),
        SizedBox(height: AppSpacing.lg.h),
        _Rise(
          index: 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16.r,
                color: colors.accent,
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text(
                  'AI fills in the amount, date, shop and category. Only the '
                  'text is read online; the photo never leaves your phone. '
                  'Works offline too.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onTap != null;
    final radius = BorderRadius.circular(AppRadius.lg.r);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: colors.surfaceRaised,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.r),
            child: Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: AppColors.tint(colors.accent),
                    borderRadius: BorderRadius.circular(AppRadius.md.r),
                  ),
                  child: Icon(icon, color: colors.accent, size: 24.r),
                ),
                SizedBox(width: AppSpacing.lg.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleSmall),
                      SizedBox(height: AppSpacing.xxs.h),
                      Text(subtitle, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child in, a little after the one before it.
class _Rise extends StatelessWidget {
  const _Rise({required this.index, required this.child});

  final int index;
  final Widget child;

  static const int _stepMs = 70;

  @override
  Widget build(BuildContext context) {
    final delay = index * _stepMs;
    final total = AppMotion.slow.inMilliseconds + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: AppMotion.standard),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12.h),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
