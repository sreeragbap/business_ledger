import 'dart:async';

import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_fade_in.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/features/reports/domain/models/report_scope.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:business_ledger/features/reports/logic/reports_cubit/reports_cubit.dart';
import 'package:business_ledger/features/reports/widgets/breakdown_list.dart';
import 'package:business_ledger/features/reports/widgets/kpi_grid.dart';
import 'package:business_ledger/features/reports/widgets/kpi_tile.dart';
import 'package:business_ledger/features/reports/widgets/report_filter_bar.dart';
import 'package:business_ledger/features/reports/widgets/report_section.dart';
import 'package:business_ledger/features/reports/widgets/stats_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The reports tab body. Takes its [ReportsCubit] from the tree; the host
/// calls `start(businessId:, currency:)` on it.
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        final cubit = context.read<ReportsCubit>();
        final gutter = AppSpacing.screenHorizontal.w;
        final firstLoad = state.statsStatus.isLoading && state.days.isEmpty;

        if (state.statsStatus.isFailure && state.days.isEmpty) {
          return AppErrorState(
            message: state.statsStatus.message,
            onRetry: () => unawaited(cubit.retry()),
          );
        }

        void scopeTo(ReportDimension dimension, BreakdownEntry entry) =>
            cubit.selectScope(
              ReportScope(
                dimension: dimension,
                id: entry.id,
                label: entry.label,
              ),
            );

        final sections = <Widget>[
          _Totals(state: state, loading: firstLoad),
          ReportSection(
            title: state.scope == null
                ? 'Income vs expenses'
                : '${state.scope!.label}: in vs out',
            subtitle: '${state.granularity.label} · ${state.range.label}',
            child: firstLoad
                ? const AppShimmer(child: ShimmerBox(height: 200))
                : StatsBarChart(
                    buckets: state.series,
                    currency: state.currency,
                    height: 200,
                  ),
          ),
          if (state.showsCash)
            ReportSection(
              title: 'Cash received vs paid',
              subtitle: 'By payment date',
              child: firstLoad
                  ? const AppShimmer(child: ShimmerBox(height: 160))
                  : StatsBarChart(
                      buckets: state.series,
                      currency: state.currency,
                      series: ChartSeries.cash,
                      height: 160,
                    ),
            ),
          if (state.scope == null) ...[
            ReportSection(
              title: 'Income by category',
              subtitle: 'Tap a category to filter',
              child: BreakdownList(
                entries: state.incomeByCategory,
                currency: state.currency,
                colour: AppColors.income,
                onTap: (entry) => scopeTo(ReportDimension.category, entry),
              ),
            ),
            ReportSection(
              title: 'Expenses by category',
              subtitle: 'Tap a category to filter',
              child: BreakdownList(
                entries: state.expenseByCategory,
                currency: state.currency,
                colour: AppColors.expense,
                onTap: (entry) => scopeTo(ReportDimension.category, entry),
              ),
            ),
            if (state.incomeByProject.isNotEmpty ||
                state.expenseByProject.isNotEmpty)
              ReportSection(
                title: 'By project',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.incomeByProject.isNotEmpty) ...[
                      Text(
                        'Income',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      BreakdownList(
                        entries: state.incomeByProject,
                        currency: state.currency,
                        colour: AppColors.income,
                        onTap: (entry) =>
                            scopeTo(ReportDimension.project, entry),
                      ),
                    ],
                    if (state.expenseByProject.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm.h),
                      Text(
                        'Expenses',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      BreakdownList(
                        entries: state.expenseByProject,
                        currency: state.currency,
                        colour: AppColors.expense,
                        onTap: (entry) =>
                            scopeTo(ReportDimension.project, entry),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppSpacing.sm.h),
            ReportFilterBar(
              range: state.range,
              onRangeChanged: (range) => unawaited(cubit.selectRange(range)),
              granularity: state.granularity,
              onGranularityChanged: cubit.selectGranularity,
              scope: state.scope,
              labels: state.labels,
              onScopeChanged: cubit.selectScope,
            ),
            SizedBox(height: AppSpacing.sm.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.sm.h,
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
            ),
          ],
        );
      },
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.state, required this.loading});

  final ReportsState state;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final totals = state.totals;
    final scoped = state.scope != null;
    return ReportSection(
      title: scoped ? state.scope!.label : 'Summary',
      subtitle: state.range.label,
      child: KpiGrid(
        children: [
          KpiTile(
            label: scoped ? 'In (confirmed)' : 'Income (confirmed)',
            minor: totals.incomeMinor,
            currency: state.currency,
            colour: AppColors.income,
            icon: Icons.trending_up_rounded,
            loading: loading,
            compact: false,
          ),
          KpiTile(
            label: scoped ? 'Out (confirmed)' : 'Expenses (confirmed)',
            minor: totals.expenseMinor,
            currency: state.currency,
            colour: AppColors.expense,
            icon: Icons.trending_down_rounded,
            loading: loading,
            compact: false,
          ),
          KpiTile(
            label: 'Net',
            caption: 'Income − expenses',
            minor: totals.netMinor,
            currency: state.currency,
            colour: AppColors.accent,
            icon: Icons.balance_rounded,
            loading: loading,
            compact: false,
          ),
          if (state.showsCash) ...[
            KpiTile(
              label: 'Cash received',
              minor: totals.cashInMinor,
              currency: state.currency,
              colour: AppColors.income,
              icon: Icons.south_west_rounded,
              loading: loading,
              compact: false,
            ),
            KpiTile(
              label: 'Cash paid',
              minor: totals.cashOutMinor,
              currency: state.currency,
              colour: AppColors.expense,
              icon: Icons.north_east_rounded,
              loading: loading,
              compact: false,
            ),
            KpiTile(
              label: 'Net cash',
              caption: 'Received − paid',
              minor: totals.netCashMinor,
              currency: state.currency,
              colour: AppColors.info,
              icon: Icons.account_balance_wallet_outlined,
              loading: loading,
              compact: false,
            ),
          ],
        ],
      ),
    );
  }
}
