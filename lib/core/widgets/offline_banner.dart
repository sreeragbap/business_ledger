import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A strip that slides in when the device goes offline.
///
/// Placed above the whole app (see `App`), so it owns the status-bar inset
/// while visible. Reads are still served from the local cache, which is what
/// the copy says.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({required this.isOffline, super.key});

  final bool isOffline;

  static const String message =
      "You're offline. Showing saved data; changes will sync later.";

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: isOffline
          ? Semantics(
              liveRegion: true,
              child: Material(
                color: AppColors.surfaceRaised,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg.w,
                    topInset + AppSpacing.sm.h,
                    AppSpacing.lg.w,
                    AppSpacing.sm.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 16.r,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: AppSpacing.sm.w),
                      Expanded(
                        child: Text(
                          message,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
