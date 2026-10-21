import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A rounded tile with the business's initials.
class BusinessAvatar extends StatelessWidget {
  const BusinessAvatar({required this.business, this.size = 40, super.key});

  final Business business;

  /// Design units.
  final double size;

  @override
  Widget build(BuildContext context) {
    final side = size.r;
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: business.archived
            ? context.colors.surfaceHigh
            : context.colors.accentMuted,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
      ),
      child: Text(
        business.initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: business.archived
              ? context.colors.textSecondary
              : context.colors.accent,
          fontSize: side * 0.36,
        ),
      ),
    );
  }
}

/// A small label for a member's role.
class RoleChip extends StatelessWidget {
  const RoleChip({required this.role, super.key});

  final Role role;

  static Color colourOf(Role role, AppPalette palette) => switch (role) {
    Role.owner => palette.accent,
    Role.admin => palette.info,
    Role.editor => palette.swatchPurple,
    Role.viewer => palette.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final colour = colourOf(role, context.colors);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.tint(colour),
        borderRadius: AppRadius.chip,
      ),
      child: Text(
        role.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colour,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
