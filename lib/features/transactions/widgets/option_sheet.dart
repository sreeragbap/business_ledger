import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One choice in an option sheet.
class OptionItem<T> {
  const OptionItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColour,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColour;
}

/// What an option sheet resolved to. Distinguishes "picked Any" (`value`
/// null) from "dismissed" (no [Picked] at all).
class Picked<T> {
  const Picked(this.value);

  final T? value;
}

/// A bottom sheet of single-choice options, with an optional "Any" row and
/// a search field for long lists.
Future<Picked<T>?> showOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<OptionItem<T>> options,
  T? selected,
  String? anyLabel,
  bool searchable = false,
  Widget? footer,
}) => showAppBottomSheet<Picked<T>>(
  context: context,
  title: title,
  child: OptionList<T>(
    options: options,
    selected: selected,
    anyLabel: anyLabel,
    searchable: searchable,
    footer: footer,
  ),
);

class OptionList<T> extends StatefulWidget {
  const OptionList({
    required this.options,
    this.selected,
    this.anyLabel,
    this.searchable = false,
    this.footer,
    super.key,
  });

  final List<OptionItem<T>> options;
  final T? selected;
  final String? anyLabel;
  final bool searchable;
  final Widget? footer;

  @override
  State<OptionList<T>> createState() => _OptionListState<T>();
}

class _OptionListState<T> extends State<OptionList<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final visible = [
      for (final option in widget.options)
        if (needle.isEmpty ||
            option.label.toLowerCase().contains(needle) ||
            (option.subtitle?.toLowerCase().contains(needle) ?? false))
          option,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.searchable) ...[
          AppTextField(
            hint: 'Search',
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: AppSpacing.sm.h),
        ],
        if (widget.anyLabel != null && needle.isEmpty)
          _OptionTile(
            label: widget.anyLabel!,
            selected: widget.selected == null,
            icon: Icons.all_inclusive_rounded,
            onTap: () => Navigator.of(context).pop(Picked<T>(null)),
          ),
        for (final option in visible)
          _OptionTile(
            label: option.label,
            subtitle: option.subtitle,
            icon: option.icon,
            iconColour: option.iconColour,
            selected: option.value == widget.selected,
            onTap: () => Navigator.of(context).pop(Picked<T>(option.value)),
          ),
        if (visible.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
            child: Text(
              needle.isEmpty ? 'Nothing to choose yet.' : 'No matches.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        if (widget.footer != null) ...[
          SizedBox(height: AppSpacing.sm.h),
          widget.footer!,
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.iconColour,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: ListTile(
        minTileHeight: 52,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
        leading: icon == null
            ? null
            : Icon(icon, color: iconColour ?? AppColors.textSecondary),
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppColors.accent)
            : null,
        onTap: onTap,
      ),
    );
  }
}
