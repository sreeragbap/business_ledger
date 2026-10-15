import 'dart:async';

import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/logic/transaction_list_cubit/transaction_list_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/option_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Search plus a row of filter chips. A set chip shows its value and an ×
/// to clear it; tapping any chip opens its choices in a sheet.
class TransactionFilterBar extends StatefulWidget {
  const TransactionFilterBar({super.key});

  @override
  State<TransactionFilterBar> createState() => _TransactionFilterBarState();
}

class _TransactionFilterBarState extends State<TransactionFilterBar> {
  late final TextEditingController _search = TextEditingController(
    text: context.read<TransactionListCubit>().state.searchText,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionListCubit>();
    return BlocBuilder<TransactionListCubit, TransactionListState>(
      buildWhen: (p, c) =>
          p.filter != c.filter ||
          p.searchText.isEmpty != c.searchText.isEmpty ||
          p.categories != c.categories ||
          p.parties != c.parties ||
          p.projects != c.projects,
      builder: (context, state) {
        final filter = state.filter;
        return Padding(
          padding: EdgeInsets.only(top: AppSpacing.xs.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal.w,
                ),
                child: AppTextField(
                  controller: _search,
                  hint: 'Search description, party, reference…',
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.search,
                  onChanged: cubit.search,
                  suffix: state.searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            cubit.search('');
                          },
                        ),
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal.w,
                  ),
                  children: [
                    _chip(
                      label: filter.sort.label,
                      icon: Icons.sort_rounded,
                      selected: filter.sort != TransactionSort.dateDesc,
                      onTap: () => _pickSort(context, filter),
                    ),
                    _chip(
                      label: filter.status?.label ?? 'Status',
                      selected: filter.status != null,
                      onTap: () => _pickStatus(context, filter),
                      onClear: () => cubit.updateFilter(
                        (f) => f.copyWith(status: () => null),
                      ),
                    ),
                    _chip(
                      label: filter.payment?.label ?? 'Payment',
                      selected: filter.payment != null,
                      onTap: () => _pickPayment(context, filter),
                      onClear: () => cubit.updateFilter(
                        (f) => f.copyWith(payment: () => null),
                      ),
                    ),
                    _chip(
                      label: filter.type?.label ?? 'Type',
                      selected: filter.type != null,
                      onTap: () => _pickType(context, filter),
                      onClear: () => cubit.updateFilter(
                        (f) => f.copyWith(type: () => null),
                      ),
                    ),
                    _chip(
                      label:
                          state.categoryName(filter.categoryId) ??
                          (filter.categoryId == null
                              ? 'Category'
                              : 'Category ✓'),
                      selected: filter.categoryId != null,
                      onTap: () => _pickCategory(context, state),
                      onClear: () => cubit.updateFilter(
                        (f) => f.copyWith(categoryId: () => null),
                      ),
                    ),
                    if (state.projects.isNotEmpty || filter.projectId != null)
                      _chip(
                        label:
                            state.projectName(filter.projectId) ??
                            (filter.projectId == null
                                ? 'Project'
                                : 'Project ✓'),
                        selected: filter.projectId != null,
                        onTap: () => _pickProject(context, state),
                        onClear: () => cubit.updateFilter(
                          (f) => f.copyWith(projectId: () => null),
                        ),
                      ),
                    if (state.parties.isNotEmpty || filter.partyId != null)
                      _chip(
                        label:
                            state.partyName(filter.partyId) ??
                            (filter.partyId == null ? 'Party' : 'Party ✓'),
                        selected: filter.partyId != null,
                        onTap: () => _pickParty(context, state),
                        onClear: () => cubit.updateFilter(
                          (f) => f.copyWith(partyId: () => null),
                        ),
                      ),
                    _chip(
                      label: _dateLabel(filter),
                      icon: Icons.date_range_rounded,
                      selected: filter.from != null || filter.to != null,
                      onTap: () => _pickDates(context, filter),
                      onClear: () => cubit.updateFilter(
                        (f) => f.copyWith(from: () => null, to: () => null),
                      ),
                    ),
                    if (filter.activeCount > 1)
                      Padding(
                        padding: EdgeInsets.only(right: AppSpacing.sm.w),
                        child: TextButton.icon(
                          onPressed: () => unawaited(cubit.clearFilters()),
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Clear all'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _dateLabel(TransactionFilter filter) {
    final from = filter.from;
    final to = filter.to;
    if (from == null && to == null) return 'Dates';
    if (from == to) return LedgerDates.formatShort(from);
    return '${from == null ? '…' : LedgerDates.formatShort(from)} – '
        '${to == null ? '…' : LedgerDates.formatShort(to)}';
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Future<void> Function()? onClear,
  }) => Padding(
    padding: EdgeInsets.only(right: AppSpacing.sm.w),
    child: Center(
      child: InputChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 18.r),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.accentMuted,
        onPressed: onTap,
        onDeleted: selected && onClear != null
            ? () => unawaited(onClear())
            : null,
        deleteButtonTooltipMessage: 'Clear $label',
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
  );

  Future<void> _apply(
    TransactionFilter Function(TransactionFilter filter) change,
  ) => context.read<TransactionListCubit>().updateFilter(change);

  Future<void> _pickSort(BuildContext context, TransactionFilter filter) async {
    final picked = await showOptionSheet<TransactionSort>(
      context: context,
      title: 'Sort by',
      selected: filter.sort,
      options: [
        for (final sort in TransactionSort.values)
          OptionItem(value: sort, label: sort.label, icon: sort.icon),
      ],
    );
    final sort = picked?.value;
    if (sort != null) await _apply((f) => f.copyWith(sort: sort));
  }

  Future<void> _pickStatus(
    BuildContext context,
    TransactionFilter filter,
  ) async {
    final picked = await showOptionSheet<TransactionStatus>(
      context: context,
      title: 'Status',
      selected: filter.status,
      anyLabel: 'Any status',
      options: [
        for (final status in TransactionStatus.values)
          OptionItem(value: status, label: status.label),
      ],
    );
    if (picked != null) {
      await _apply((f) => f.copyWith(status: () => picked.value));
    }
  }

  Future<void> _pickPayment(
    BuildContext context,
    TransactionFilter filter,
  ) async {
    final picked = await showOptionSheet<PaymentFilter>(
      context: context,
      title: 'Payment',
      selected: filter.payment,
      anyLabel: 'Any',
      options: [
        for (final payment in PaymentFilter.values)
          OptionItem(
            value: payment,
            label: payment.label,
            icon: payment == PaymentFilter.overdue
                ? Icons.schedule_rounded
                : null,
            iconColour: payment == PaymentFilter.overdue
                ? AppColors.warning
                : null,
          ),
      ],
    );
    if (picked != null) {
      await _apply((f) => f.copyWith(payment: () => picked.value));
    }
  }

  Future<void> _pickType(BuildContext context, TransactionFilter filter) async {
    final picked = await showOptionSheet<TransactionType>(
      context: context,
      title: 'Type',
      selected: filter.type,
      anyLabel: 'Any type',
      options: [
        for (final type in TransactionType.values)
          OptionItem(value: type, label: type.label),
      ],
    );
    if (picked != null) {
      await _apply((f) => f.copyWith(type: () => picked.value));
    }
  }

  Future<void> _pickCategory(
    BuildContext context,
    TransactionListState state,
  ) async {
    final picked = await showOptionSheet<String>(
      context: context,
      title: 'Category',
      selected: state.filter.categoryId,
      anyLabel: 'Any category',
      searchable: state.categories.length > 8,
      options: [
        for (final category in state.categories)
          OptionItem(
            value: category.id,
            label: category.name,
            subtitle: category.archived ? 'Archived' : category.kind.label,
            icon: category.icon.icon,
            iconColour: category.colour.color,
          ),
      ],
    );
    if (picked != null) {
      await _apply((f) => f.copyWith(categoryId: () => picked.value));
    }
  }

  Future<void> _pickProject(
    BuildContext context,
    TransactionListState state,
  ) async {
    final picked = await showOptionSheet<String>(
      context: context,
      title: 'Project',
      selected: state.filter.projectId,
      anyLabel: 'Any project',
      searchable: state.projects.length > 8,
      options: [
        for (final project in state.projects)
          OptionItem(
            value: project.id,
            label: project.displayName,
            subtitle: project.archived ? 'Archived' : null,
          ),
      ],
    );
    if (picked != null) {
      await _apply((f) => f.copyWith(projectId: () => picked.value));
    }
  }

  Future<void> _pickParty(
    BuildContext context,
    TransactionListState state,
  ) async {
    final picked = await showOptionSheet<String>(
      context: context,
      title: 'Customer or supplier',
      selected: state.filter.partyId,
      anyLabel: 'Anyone',
      searchable: state.parties.length > 8,
      options: [
        for (final party in state.parties)
          OptionItem(
            value: party.id,
            label: party.name,
            subtitle: party.archived ? 'Archived' : party.kind.label,
            icon: party.kind.icon,
          ),
      ],
    );
    if (picked != null) {
      await _apply((f) => f.copyWith(partyId: () => picked.value));
    }
  }

  Future<void> _pickDates(
    BuildContext context,
    TransactionFilter filter,
  ) async {
    final from = LedgerDates.parse(filter.from);
    final to = LedgerDates.parse(filter.to);
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: from != null && to != null
          ? DateTimeRange(start: from, end: to)
          : null,
      helpText: 'Transaction dates',
    );
    if (range == null) return;
    await _apply(
      (f) => f.copyWith(
        from: () => LedgerDates.key(range.start),
        to: () => LedgerDates.key(range.end),
      ),
    );
  }
}
