import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A small uppercase heading above a group of rows, with an optional
/// trailing widget (a count, an action).
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xs.w,
        right: AppSpacing.xs.w,
        bottom: AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A heading that expands and collapses [child] with a size animation. Used
/// for secondary content such as archived items.
class AppCollapsibleSection extends StatefulWidget {
  const AppCollapsibleSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.count,
    super.key,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  /// Shown after the title, e.g. how many archived items there are.
  final int? count;

  @override
  State<AppCollapsibleSection> createState() => _AppCollapsibleSectionState();
}

class _AppCollapsibleSectionState extends State<AppCollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = widget.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs.w,
                vertical: AppSpacing.md.h,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      count == null
                          ? widget.title.toUpperCase()
                          : '${widget.title.toUpperCase()} · $count',
                      style: textTheme.labelSmall,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppMotion.medium,
                    curve: AppMotion.standard,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 20.r,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: _expanded
              ? widget.child
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
