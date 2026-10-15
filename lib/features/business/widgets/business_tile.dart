import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/widgets/business_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One business in a list: avatar, name, currency and time zone, with a
/// check when it is the current one.
class BusinessTile extends StatelessWidget {
  const BusinessTile({
    required this.business,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final Business business;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      business.currency.code,
      business.timezone,
      if (business.archived) 'Archived',
    ].join(' · ');
    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.accent : null,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.md.h,
      ),
      child: Row(
        children: [
          BusinessAvatar(business: business),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xxs.h),
                Text(
                  subtitle,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (selected)
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.accent,
              size: 22.r,
            )
          else
            Icon(Icons.chevron_right_rounded, size: 22.r),
        ],
      ),
    );
  }
}
