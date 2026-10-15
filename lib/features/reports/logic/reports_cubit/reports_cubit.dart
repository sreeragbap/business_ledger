import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/reports/domain/logic/report_aggregator.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/report_scope.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:business_ledger/features/reports/domain/models/stats_totals.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:business_ledger/features/reports/domain/repository/reports_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'reports_state.dart';

/// Reports over a date range, by day/week/month, optionally narrowed to one
/// category, project or type, with category and project breakdowns.
///
/// Only a range change queries again; granularity and scope recompute from
/// the days already held.
@injectable
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repository) : super(ReportsState.initial());

  final ReportsRepository _repository;
  StreamSubscription<AppResult<List<DailyStats>>>? _stats;

  Future<void> start({
    required String businessId,
    required Currency currency,
    DateTime? now,
  }) async {
    final range = ReportRange.preset(
      DateRangePreset.thisMonth,
      CalendarDay.today(now),
    );
    emit(
      ReportsState(
        businessId: businessId,
        currency: currency,
        range: range,
        granularity: ReportAggregator.defaultGranularity(range),
      ),
    );
    await Future.wait([_watch(), _loadLabels()]);
  }

  Future<void> selectPreset(DateRangePreset preset, {DateTime? now}) =>
      selectRange(ReportRange.preset(preset, CalendarDay.today(now)));

  Future<void> selectRange(ReportRange range) async {
    if (range == state.range) return;
    emit(
      state.copyWith(
        range: range,
        granularity: ReportAggregator.defaultGranularity(range),
      ),
    );
    await _watch();
  }

  void selectGranularity(ReportGranularity granularity) {
    if (granularity == state.granularity) return;
    emit(_derive(state.copyWith(granularity: granularity)));
  }

  /// `null` clears the filter.
  void selectScope(ReportScope? scope) {
    if (scope == state.scope) return;
    emit(_derive(state.copyWith(scope: scope, clearScope: scope == null)));
  }

  Future<void> retry() => Future.wait([_watch(), _loadLabels()]);

  Future<void> _watch() async {
    final businessId = state.businessId;
    if (businessId == null) return;
    await _stats?.cancel();
    final range = state.range;
    emit(state.copyWith(statsStatus: const Status.loading()));
    _stats = _repository
        .watchStats(businessId, from: range.fromKey, to: range.toKey)
        .listen(
          (result) => result.when(
            success: (days) => emit(
              _derive(
                state.copyWith(days: days, statsStatus: const Status.success()),
              ),
            ),
            failure: (error) =>
                emit(state.copyWith(statsStatus: Status.fromException(error))),
          ),
        );
  }

  Future<void> _loadLabels() async {
    final businessId = state.businessId;
    if (businessId == null) return;
    emit(state.copyWith(labelsStatus: const Status.loading()));
    final result = await _repository.labels(businessId);
    if (isClosed) return;
    result.when(
      success: (labels) => emit(
        _derive(
          state.copyWith(labels: labels, labelsStatus: const Status.success()),
        ),
      ),
      // Without names the report still works; ids show as "Other".
      failure: (error) =>
          emit(state.copyWith(labelsStatus: Status.fromException(error))),
    );
  }

  /// Recomputes every derived figure from the held days and the filters.
  static ReportsState _derive(ReportsState s) {
    final unscoped = ReportAggregator.sum(s.days, range: s.range);
    final totals = s.scope == null
        ? unscoped
        : ReportAggregator.sum(s.days, range: s.range, scope: s.scope);
    final categories = s.labels.categories;
    final projects = s.labels.projects;
    return s.copyWith(
      totals: totals,
      series: ReportAggregator.series(
        s.days,
        range: s.range,
        granularity: s.granularity,
        scope: s.scope,
      ),
      incomeByCategory: ReportAggregator.breakdown(
        unscoped.byCategory,
        side: Direction.inflow,
        labels: categories,
        unknownLabel: 'Uncategorised',
      ),
      expenseByCategory: ReportAggregator.breakdown(
        unscoped.byCategory,
        side: Direction.outflow,
        labels: categories,
        unknownLabel: 'Uncategorised',
      ),
      incomeByProject: ReportAggregator.breakdown(
        unscoped.byProject,
        side: Direction.inflow,
        labels: projects,
        unknownLabel: 'Unknown project',
      ),
      expenseByProject: ReportAggregator.breakdown(
        unscoped.byProject,
        side: Direction.outflow,
        labels: projects,
        unknownLabel: 'Unknown project',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _stats?.cancel();
    return super.close();
  }
}
