import 'dart:async';

import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_fade_in.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:business_ledger/features/reports/logic/dashboard_cubit/dashboard_cubit.dart';
import 'package:business_ledger/features/reports/widgets/kpi_grid.dart';
import 'package:business_ledger/features/reports/widgets/kpi_tile.dart';
import 'package:business_ledger/features/reports/widgets/report_filter_bar.dart';
import 'package:business_ledger/features/reports/widgets/report_section.dart';
import 'package:business_ledger/features/reports/widgets/stats_bar_chart.dart';
import 'package:business_ledger/features/reports/widgets/transaction_row_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The dashboard body for one business. Takes its [DashboardCubit] from the
/// tree; the host calls `start(businessId:, currency:)` on it.
///
/// Income/expense (recognised) and cash (received/paid) are separate
/// sections, and money still owed is labelled as outstanding, never as
/// income.
class DashboardView extends StatelessWidget {
  const DashboardView({
    this.header,
    this.onTransactionTap,
    this.onSeeAllPending,
    this.onSeeAllRecent,
    super.key,
  });

  /// Shown above the figures (a greeting, the business switcher).
  final Widget? header;
  final ValueChanged<TransactionRow>? onTransactionTap;
  final VoidCallback? onSeeAllPending;
  final VoidCallback? onSeeAllRecent;

  static const List<DateRangePreset> presets = [
    DateRangePreset.today,
    DateRangePreset.thisWeek,
    DateRangePreset.thisMonth,
    DateRangePreset.thisYear,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final cubit = context.read<DashboardCubit>();
        final gutter = AppSpacing.screenHorizontal.w;
        final sections = <Widget>[
          ?header,
          _PresetChips(state: state),
          _ProfitAndLoss(state: state),
          _CashFlow(state: state),
          _Outstanding(state: state),
          ReportSection(
            title: 'Income vs expenses',
            subtitle: state.range.label,
            child: state.isLoadingFirst
                ? const AppShimmer(child: ShimmerBox(height: 180))
                : StatsBarChart(
                    buckets: state.series,
                    currency: state.currency,
                  ),
          ),
          _PendingList(
            state: state,
            onTap: onTransactionTap,
            onSeeAll: onSeeAllPending,
          ),
          _RecentList(
            state: state,
            onTap: onTransactionTap,
            onSeeAll: onSeeAllRecent,
          ),
          _PeriodSummary(state: state),
        ];

        return RefreshIndicator(
          onRefresh: cubit.refresh,
          color: context.colors.accent,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              gutter,
              AppSpacing.lg.h,
              gutter,
              AppSpacing.huge.h,
            ),
            itemCount: sections.length,
            separatorBuilder: (_, _) => SizedBox(height: AppSpacing.lg.h),
            itemBuilder: (context, index) => AppFadeIn(
              delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
              child: sections[index],
            ),
          ),
        );
      },
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final preset in DashboardView.presets) ...[
            ChoiceChip(
              label: Text(preset.label),
              selected: state.range.preset == preset,
              onSelected: (_) => unawaited(cubit.selectPreset(preset)),
            ),
            SizedBox(width: AppSpacing.sm.w),
          ],
          ActionChip(
            avatar: Icon(Icons.date_range_rounded, size: 16.r),
            label: Text(
              state.range.preset == DateRangePreset.custom
                  ? state.range.label
                  : 'More',
            ),
            onPressed: () async {
              final picked = await showReportRangeSheet(
                context: context,
                current: state.range,
                today: CalendarDay.parse(state.today),
              );
              if (picked != null) await cubit.selectRange(picked);
            },
          ),
        ],
      ),
    );
  }
}

class _ProfitAndLoss extends StatelessWidget {
  const _ProfitAndLoss({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final totals = state.totals;
    final loading = state.isLoadingFirst;
    return ReportSection(
      title: 'Income & expenses',
      subtitle: '${state.range.title} · confirmed entries, by date',
      child: KpiGrid(
        children: [
          KpiTile(
            label: 'Income (confirmed)',
            minor: totals.incomeMinor,
            currency: state.currency,
            colour: context.colors.income,
            icon: Icons.trending_up_rounded,
            loading: loading,
          ),
          KpiTile(
            label: 'Expenses (confirmed)',
            minor: totals.expenseMinor,
            currency: state.currency,
            colour: context.colors.expense,
            icon: Icons.trending_down_rounded,
            loading: loading,
          ),
          KpiTile(
            label: totals.netMinor >= 0 ? 'Net profit' : 'Net loss',
            minor: totals.netMinor,
            currency: state.currency,
            colour: totals.netMinor >= 0
                ? context.colors.accent
                : context.colors.warning,
            icon: Icons.balance_rounded,
            caption: 'Income − expenses',
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _CashFlow extends StatelessWidget {
  const _CashFlow({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final totals = state.totals;
    final loading = state.isLoadingFirst;
    return ReportSection(
      title: 'Cash flow',
      subtitle: 'Money that actually moved, by payment date',
      child: KpiGrid(
        children: [
          KpiTile(
            label: 'Cash received',
            minor: totals.cashInMinor,
            currency: state.currency,
            colour: context.colors.income,
            icon: Icons.south_west_rounded,
            loading: loading,
          ),
          KpiTile(
            label: 'Cash paid',
            minor: totals.cashOutMinor,
            currency: state.currency,
            colour: context.colors.expense,
            icon: Icons.north_east_rounded,
            loading: loading,
          ),
          KpiTile(
            label: 'Net cash',
            minor: totals.netCashMinor,
            currency: state.currency,
            colour: context.colors.info,
            icon: Icons.account_balance_wallet_outlined,
            caption: 'Received − paid',
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _Outstanding extends StatelessWidget {
  const _Outstanding({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final balances = state.balances;
    final loading = balances == null && !state.balancesStatus.isFailure;
    final textTheme = Theme.of(context).textTheme;
    return ReportSection(
      title: 'Outstanding',
      subtitle: 'All open confirmed entries, any date',
      trailing: state.balancesStatus.isFailure && balances == null
          ? AppButton.text(
              label: 'Retry',
              onPressed: () =>
                  unawaited(context.read<DashboardCubit>().loadBalances()),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiGrid(
            children: [
              KpiTile(
                label: 'Receivables',
                caption: 'Outstanding — not yet received',
                minor: balances?.receivableMinor ?? 0,
                currency: state.currency,
                colour: context.colors.info,
                icon: Icons.call_received_rounded,
                loading: loading,
              ),
              KpiTile(
                label: 'Payables',
                caption: 'Outstanding — not yet paid',
                minor: balances?.payableMinor ?? 0,
                currency: state.currency,
                colour: context.colors.warning,
                icon: Icons.call_made_rounded,
                loading: loading,
              ),
            ],
          ),
          if (balances?.fromCache ?? false) ...[
            SizedBox(height: AppSpacing.sm.h),
            Text(
              'Offline: summed from entries saved on this device; may be '
              'incomplete.',
              style: textTheme.bodySmall?.copyWith(
                color: context.colors.warning,
              ),
            ),
          ],
          if (state.balancesStatus.isFailure && balances == null) ...[
            SizedBox(height: AppSpacing.sm.h),
            Text(state.balancesStatus.message, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.state, this.onTap, this.onSeeAll});

  final DashboardState state;
  final ValueChanged<TransactionRow>? onTap;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final overdue = state.overdue.length;
    return ReportSection(
      title: 'Pending & overdue',
      subtitle: overdue == 0
          ? 'Unsettled entries, earliest due first'
          : '$overdue overdue · earliest due first',
      trailing: onSeeAll == null
          ? null
          : AppButton.text(label: 'See all', onPressed: onSeeAll),
      child: _RowList(
        rows: state.pending,
        status: state.pendingStatus,
        state: state,
        showOutstanding: true,
        emptyText: 'Nothing pending. Every confirmed entry is settled.',
        onTap: onTap,
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.state, this.onTap, this.onSeeAll});

  final DashboardState state;
  final ValueChanged<TransactionRow>? onTap;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return ReportSection(
      title: 'Recent transactions',
      trailing: onSeeAll == null
          ? null
          : AppButton.text(label: 'See all', onPressed: onSeeAll),
      child: _RowList(
        rows: state.recent,
        status: state.recentStatus,
        state: state,
        emptyText: 'No transactions yet.',
        onTap: onTap,
      ),
    );
  }
}

class _RowList extends StatelessWidget {
  const _RowList({
    required this.rows,
    required this.status,
    required this.state,
    required this.emptyText,
    this.showOutstanding = false,
    this.onTap,
  });

  final List<TransactionRow> rows;
  final Status status;
  final DashboardState state;
  final String emptyText;
  final bool showOutstanding;
  final ValueChanged<TransactionRow>? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (rows.isEmpty) {
      if (status.isLoading) {
        return const AppShimmer(
          child: Column(
            children: [
              ShimmerBox(height: 40),
              SizedBox(height: AppSpacing.sm),
              ShimmerBox(height: 40),
            ],
          ),
        );
      }
      return Text(
        status.isFailure ? status.message : emptyText,
        style: textTheme.bodyMedium,
      );
    }
    return Column(
      children: [
        for (final row in rows)
          TransactionRowTile(
            row: row,
            currency: state.currency,
            today: state.today,
            showOutstanding: showOutstanding,
            onTap: onTap == null ? null : () => onTap!(row),
          ),
      ],
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totals = state.totals;
    final currency = state.currency;
    final String text;
    if (totals.isEmpty) {
      text = 'No confirmed activity in ${state.range.label}.';
    } else {
      final net = totals.netMinor;
      final cash = totals.netCashMinor;
      text =
          '${state.range.title}: ${net >= 0 ? 'a profit' : 'a loss'} of '
          '${Money.format(net.abs(), currency)} on confirmed entries, and '
          '${cash >= 0 ? 'a net cash inflow' : 'a net cash outflow'} of '
          '${Money.format(cash.abs(), currency)}.';
    }
    return ReportSection(
      title: 'Period summary',
      subtitle: state.range.label,
      child: Text(text, style: textTheme.bodyLarge),
    );
  }
}
