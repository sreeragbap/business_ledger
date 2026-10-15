import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/reports/domain/logic/report_aggregator.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:business_ledger/features/reports/domain/models/stats_totals.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:business_ledger/features/reports/domain/repository/reports_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'dashboard_state.dart';

/// The home screen's figures for one business: period totals, cash, what
/// is owed each way, pending/overdue and recent entries. Live: every list
/// follows its Firestore query.
@injectable
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(DashboardState.initial());

  final ReportsRepository _repository;

  static const int pendingLimit = 8;
  static const int recentLimit = 6;

  StreamSubscription<AppResult<List<DailyStats>>>? _stats;
  StreamSubscription<AppResult<List<TransactionRow>>>? _pending;
  StreamSubscription<AppResult<List<TransactionRow>>>? _recent;

  /// Starts (or restarts, for another business) every subscription.
  Future<void> start({
    required String businessId,
    required Currency currency,
    DateTime? now,
  }) async {
    final today = CalendarDay.today(now);
    final preset = state.range.preset == DateRangePreset.custom
        ? state.range
        : ReportRange.preset(state.range.preset, today);
    emit(
      DashboardState(
        businessId: businessId,
        currency: currency,
        range: preset,
        today: CalendarDay.key(today),
        pendingStatus: const Status.loading(),
        recentStatus: const Status.loading(),
      ),
    );

    await _pending?.cancel();
    _pending = _repository
        .openTransactions(businessId, limit: pendingLimit)
        .listen(
          (result) => result.when(
            success: (rows) => emit(
              state.copyWith(
                pending: rows,
                pendingStatus: const Status.success(),
              ),
            ),
            failure: (error) => emit(
              state.copyWith(pendingStatus: Status.fromException(error)),
            ),
          ),
        );

    await _recent?.cancel();
    _recent = _repository
        .recentTransactions(businessId, limit: recentLimit)
        .listen(
          (result) => result.when(
            success: (rows) => emit(
              state.copyWith(
                recent: rows,
                recentStatus: const Status.success(),
              ),
            ),
            failure: (error) =>
                emit(state.copyWith(recentStatus: Status.fromException(error))),
          ),
        );

    await Future.wait([_watchStats(), loadBalances()]);
  }

  Future<void> selectPreset(DateRangePreset preset) => selectRange(
    ReportRange.preset(preset, CalendarDay.parse(state.today)),
  );

  Future<void> selectRange(ReportRange range) async {
    if (range == state.range) return;
    emit(state.copyWith(range: range));
    await _watchStats();
  }

  /// Receivables and payables are an aggregate, not a live query: refreshed
  /// on start and on pull-to-refresh.
  Future<void> loadBalances() async {
    final businessId = state.businessId;
    if (businessId == null) return;
    emit(state.copyWith(balancesStatus: const Status.loading()));
    final result = await _repository.receivablesAndPayables(businessId);
    if (isClosed) return;
    result.when(
      success: (balances) => emit(
        state.copyWith(
          balances: balances,
          balancesStatus: const Status.success(),
        ),
      ),
      failure: (error) =>
          emit(state.copyWith(balancesStatus: Status.fromException(error))),
    );
  }

  Future<void> refresh() => loadBalances();

  Future<void> _watchStats() async {
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
              state.copyWith(
                totals: ReportAggregator.sum(days, range: range),
                series: ReportAggregator.series(
                  days,
                  range: range,
                  granularity: ReportAggregator.defaultGranularity(range),
                ),
                statsStatus: const Status.success(),
              ),
            ),
            failure: (error) =>
                emit(state.copyWith(statsStatus: Status.fromException(error))),
          ),
        );
  }

  @override
  Future<void> close() async {
    await Future.wait([
      ?_stats?.cancel(),
      ?_pending?.cancel(),
      ?_recent?.cancel(),
    ]);
    return super.close();
  }
}
