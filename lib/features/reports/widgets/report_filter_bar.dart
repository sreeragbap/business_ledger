import 'dart:async';

import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/report_scope.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opens the range picker sheet: presets, plus a custom range via the
/// Material date range picker. Returns the chosen range, or `null`.
Future<ReportRange?> showReportRangeSheet({
  required BuildContext context,
  required ReportRange current,
  DateTime? today,
}) => showAppBottomSheet<ReportRange>(
  context: context,
  title: 'Date range',
  child: _RangeSheet(current: current, today: CalendarDay.today(today)),
);

class _RangeSheet extends StatelessWidget {
  const _RangeSheet({required this.current, required this.today});

  final ReportRange current;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final preset in DateRangePreset.values)
          if (preset != DateRangePreset.custom)
            _option(
              context,
              title: preset.label,
              subtitle: ReportRange.preset(preset, today).label,
              selected: current.preset == preset,
              onTap: () => Navigator.of(
                context,
              ).pop(ReportRange.preset(preset, today)),
            ),
        _option(
          context,
          title: 'Custom range…',
          subtitle: current.preset == DateRangePreset.custom
              ? current.label
              : 'Pick start and end dates',
          selected: current.preset == DateRangePreset.custom,
          trailing: Icon(
            Icons.date_range_rounded,
            color: AppColors.textSecondary,
            size: 20.r,
          ),
          onTap: () async {
            final navigator = Navigator.of(context);
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(today.year + 5, 12, 31),
              initialDateRange: DateTimeRange(
                start: DateTime(
                  current.from.year,
                  current.from.month,
                  current.from.day,
                ),
                end: DateTime(
                  current.to.year,
                  current.to.month,
                  current.to.day,
                ),
              ),
              helpText: 'Report period',
            );
            if (picked == null) return;
            navigator.pop(ReportRange.custom(picked.start, picked.end));
          },
        ),
        SizedBox(height: AppSpacing.sm.h),
        Text(
          'Figures are by transaction date; cash by payment date.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _option(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(subtitle),
    selected: selected,
    selectedColor: AppColors.accent,
    trailing:
        trailing ??
        (selected
            ? Icon(Icons.check_rounded, color: AppColors.accent, size: 20.r)
            : null),
    onTap: onTap,
  );
}

/// A row of chips: the date range (opens [showReportRangeSheet]), the
/// granularity, and the scope filter.
class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    required this.range,
    required this.onRangeChanged,
    this.granularity,
    this.onGranularityChanged,
    this.scope,
    this.labels = ReportLabels.empty,
    this.onScopeChanged,
    this.today,
    super.key,
  });

  final ReportRange range;
  final ValueChanged<ReportRange> onRangeChanged;
  final ReportGranularity? granularity;
  final ValueChanged<ReportGranularity>? onGranularityChanged;
  final ReportScope? scope;
  final ReportLabels labels;

  /// `null` clears the scope. Hidden when not given.
  final ValueChanged<ReportScope?>? onScopeChanged;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal.w),
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(Icons.calendar_today_rounded, size: 16.r),
            label: Text(range.title),
            tooltip: 'Change date range: ${range.label}',
            onPressed: () => unawaited(_pickRange(context)),
          ),
          if (granularity != null && onGranularityChanged != null) ...[
            SizedBox(width: AppSpacing.sm.w),
            for (final option in ReportGranularity.values) ...[
              ChoiceChip(
                label: Text(option.label),
                selected: option == granularity,
                onSelected: (_) => onGranularityChanged!(option),
              ),
              SizedBox(width: AppSpacing.xs.w),
            ],
          ],
          if (onScopeChanged != null) ...[
            SizedBox(width: AppSpacing.sm.w),
            if (scope != null)
              InputChip(
                label: Text('${scope!.dimension.label}: ${scope!.label}'),
                selected: true,
                onDeleted: () => onScopeChanged!(null),
                deleteButtonTooltipMessage: 'Clear filter',
                onPressed: () => unawaited(_pickScope(context)),
              )
            else
              ActionChip(
                avatar: Icon(Icons.filter_list_rounded, size: 16.r),
                label: const Text('Filter'),
                onPressed: () => unawaited(_pickScope(context)),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showReportRangeSheet(
      context: context,
      current: range,
      today: today,
    );
    if (picked != null) onRangeChanged(picked);
  }

  Future<void> _pickScope(BuildContext context) async {
    final picked = await showAppBottomSheet<ReportScope>(
      context: context,
      title: 'Show only',
      child: _ScopeSheet(labels: labels, current: scope),
    );
    if (picked != null) onScopeChanged?.call(picked);
  }
}

class _ScopeSheet extends StatelessWidget {
  const _ScopeSheet({required this.labels, required this.current});

  final ReportLabels labels;
  final ReportScope? current;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = <(ReportDimension, List<ReportScope>)>[
      (
        ReportDimension.type,
        [
          for (final type in TransactionType.values)
            if (type.isCreatable && type != TransactionType.payment)
              ReportScope.type(type),
        ],
      ),
      (
        ReportDimension.category,
        [
          for (final MapEntry(:key, :value) in _sorted(labels.categories))
            ReportScope(
              dimension: ReportDimension.category,
              id: key,
              label: value,
            ),
        ],
      ),
      (
        ReportDimension.project,
        [
          for (final MapEntry(:key, :value) in _sorted(labels.projects))
            ReportScope(
              dimension: ReportDimension.project,
              id: key,
              label: value,
            ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'One filter at a time. Cash figures are hidden while filtering: '
          'payments are not split by category.',
          style: textTheme.bodySmall,
        ),
        for (final (dimension, options) in groups)
          if (options.isNotEmpty) ...[
            SizedBox(height: AppSpacing.lg.h),
            Text(dimension.label, style: textTheme.titleSmall),
            SizedBox(height: AppSpacing.sm.h),
            Wrap(
              spacing: AppSpacing.sm.w,
              runSpacing: AppSpacing.sm.h,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: option == current,
                    onSelected: (_) => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ],
      ],
    );
  }

  static List<MapEntry<String, String>> _sorted(Map<String, String> names) =>
      names.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
}
