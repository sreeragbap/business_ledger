import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// "Pending sync" (or "Needs attention") on a transaction with actions
/// still in the outbox. Nothing for [SyncMark.none].
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({required this.mark, super.key});

  final SyncMark mark;

  static const String pendingLabel = 'Pending sync';
  static const String failedLabel = 'Needs attention';

  @override
  Widget build(BuildContext context) {
    final failed = mark == SyncMark.failed;
    final colour = failed ? context.colors.error : context.colors.warning;
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      child: mark == SyncMark.none
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(mark),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs.w + 2,
                vertical: AppSpacing.xxs.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.tint(colour),
                borderRadius: AppRadius.chip,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : Icons.cloud_upload_outlined,
                    size: 12.r,
                    color: colour,
                  ),
                  SizedBox(width: AppSpacing.xxs.w + 1),
                  Flexible(
                    child: Text(
                      failed ? failedLabel : pendingLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: colour),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
