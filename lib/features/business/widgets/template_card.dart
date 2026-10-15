import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A selectable template. When selected it expands to preview what will be
/// seeded: categories by kind, and the custom fields they carry.
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final BusinessTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? AppColors.accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm.r),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentMuted
                        : AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.md.r),
                  ),
                  child: Icon(
                    template.icon,
                    size: 22.r,
                    color: selected ? AppColors.accent : null,
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.label, style: textTheme.titleMedium),
                      Text(template.description, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    key: ValueKey(selected),
                    color: selected ? AppColors.accent : null,
                    size: 22.r,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: selected
                  ? _Preview(template: template)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.template});

  final BusinessTemplate template;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (template.categories.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: AppSpacing.md.h),
        child: Text(
          'No categories are created. Add your own from Settings.',
          style: textTheme.bodyMedium,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.lg.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final kind in CategoryKind.values)
            if (template.categories.any((c) => c.kind == kind)) ...[
              Text(
                '${kind.label} categories'.toUpperCase(),
                style: textTheme.labelSmall,
              ),
              SizedBox(height: AppSpacing.sm.h),
              Wrap(
                spacing: AppSpacing.sm.w,
                runSpacing: AppSpacing.sm.h,
                children: [
                  for (final category in template.categories)
                    if (category.kind == kind) _CategoryPill(category),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
            ],
          if (template.fields.isNotEmpty) ...[
            Text('CUSTOM FIELDS', style: textTheme.labelSmall),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              template.fields
                  .map((field) => '${field.label} (${field.type.label})')
                  .join(', '),
              style: textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill(this.category);

  final TemplateCategory category;

  @override
  Widget build(BuildContext context) {
    final colour = category.colour.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.tint(colour),
        borderRadius: AppRadius.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon.icon, size: 14.r, color: colour),
          SizedBox(width: AppSpacing.xs.w),
          Text(
            category.name,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colour),
          ),
        ],
      ),
    );
  }
}
