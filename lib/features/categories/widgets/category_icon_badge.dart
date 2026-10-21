import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/features/categories/domain/const/category_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A category's icon on its colour's tint.
class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    required this.icon,
    required this.colour,
    this.size = 36,
    this.muted = false,
    super.key,
  });

  final CategoryIcon icon;
  final CategoryColour colour;

  /// Design units.
  final double size;

  /// Greyed out, for archived categories.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colour = muted
        ? context.colors.textTertiary
        : this.colour.colorIn(context.colors);
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        color: AppColors.tint(colour),
        shape: BoxShape.circle,
      ),
      child: Icon(icon.icon, size: size.r * 0.5, color: colour),
    );
  }
}
