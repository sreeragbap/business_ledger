import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/report_scope.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:business_ledger/features/reports/logic/dashboard_cubit/dashboard_cubit.dart';
import 'package:business_ledger/features/reports/logic/reports_cubit/reports_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reports_fixtures.dart';
import 'stub_reports_repository.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late StubReportsRepository repository;

  setUp(() => repository = StubReportsRepository());
  tearDown(() => repository.dispose());

  group('DashboardCubit', () {
    blocTest<DashboardCubit, DashboardState>(
      'start loads totals, cash, balances, pending and recent',
      build: () => DashboardCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        repository.stats.add(Success(octoberDays));
        repository.open.add(const Success([overdueSale, upcomingBill]));
        repository.recent.add(const Success([upcomingBill]));
        await settle();
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(repository.statsQueries, [('2026-10-01', '2026-10-31')]);
        expect(state.today, '2026-10-14');
        expect(state.totals.incomeMinor, 120000);
        expect(state.totals.expenseMinor, 30000);
        expect(state.totals.netMinor, 90000);
        expect(state.totals.cashInMinor, 80000);
        expect(state.totals.cashOutMinor, 30000);
        expect(state.series, hasLength(31));
        expect(state.balances?.receivableMinor, 50000);
        expect(state.balances?.payableMinor, 12000);
        expect(state.pending, hasLength(2));
        expect(state.overdue, [overdueSale]);
        expect(state.recent, [upcomingBill]);
        expect(state.statsStatus.isSuccess, isTrue);
        expect(state.balancesStatus.isSuccess, isTrue);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'changing the preset re-queries the new range',
      build: () => DashboardCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        await cubit.selectPreset(DateRangePreset.thisWeek);
        await cubit.selectPreset(DateRangePreset.thisWeek);
      },
      verify: (cubit) {
        expect(repository.statsQueries, [
          ('2026-10-01', '2026-10-31'),
          ('2026-10-12', '2026-10-18'),
        ]);
        expect(cubit.state.range.preset, DateRangePreset.thisWeek);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'a failed aggregate is reported without touching the rest',
      setUp: () => repository.balances = const Failure(AppException.offline()),
      build: () => DashboardCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        repository.stats.add(Success(octoberDays));
        await settle();
      },
      verify: (cubit) {
        expect(cubit.state.balancesStatus.error?.isOffline, isTrue);
        expect(cubit.state.balances, isNull);
        expect(cubit.state.totals.incomeMinor, 120000);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'refresh reloads the balances',
      build: () => DashboardCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        await cubit.refresh();
      },
      verify: (_) => expect(repository.balanceCalls, 2),
    );
  });

  group('ReportsCubit', () {
    blocTest<ReportsCubit, ReportsState>(
      'start derives totals, series and breakdowns with names',
      build: () => ReportsCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        repository.stats.add(Success(octoberDays));
        await settle();
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state.granularity, ReportGranularity.daily);
        expect(state.totals.incomeMinor, 120000);
        expect(state.series, hasLength(31));
        expect(state.incomeByCategory.single.label, 'Sales');
        expect(state.incomeByCategory.single.shareBasisPoints, 10000);
        expect(state.expenseByCategory.single.label, 'Rent');
        expect(state.incomeByProject.single.label, 'Fit-out');
        expect(state.showsCash, isTrue);
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'granularity and scope recompute without a new query',
      build: () => ReportsCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        repository.stats.add(Success(octoberDays));
        await settle();
        cubit
          ..selectGranularity(ReportGranularity.weekly)
          ..selectScope(
            const ReportScope(
              dimension: ReportDimension.category,
              id: 'c1',
              label: 'Sales',
            ),
          );
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(repository.statsQueries, hasLength(1));
        // Oct 2026: weeks from Mon 28 Sep to Mon 26 Oct.
        expect(state.series, hasLength(5));
        expect(state.series.map((b) => b.incomeMinor), [
          100000,
          20000,
          0,
          0,
          0,
        ]);
        expect(state.totals.incomeMinor, 120000);
        expect(state.totals.expenseMinor, 0);
        expect(state.totals.cashInMinor, 0);
        expect(state.showsCash, isFalse);
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'clearing the scope restores cash; a new range re-queries',
      build: () => ReportsCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        repository.stats.add(Success(octoberDays));
        await settle();
        cubit
          ..selectScope(ReportScope.type(TransactionType.sale))
          ..selectScope(null);
        await cubit.selectPreset(DateRangePreset.thisYear, now: now);
      },
      verify: (cubit) {
        expect(cubit.state.scope, isNull);
        expect(cubit.state.granularity, ReportGranularity.monthly);
        expect(repository.statsQueries.last, ('2026-01-01', '2026-12-31'));
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'a stats failure is surfaced',
      build: () => ReportsCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        repository.stats.add(const Failure(AppException.offline()));
        await settle();
      },
      verify: (cubit) => expect(cubit.state.statsStatus.isFailure, isTrue),
    );

    blocTest<ReportsCubit, ReportsState>(
      'missing labels fall back to placeholders',
      setUp: () =>
          repository.labelsResult = const Failure(AppException.offline()),
      build: () => ReportsCubit(repository),
      act: (cubit) async {
        await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
        repository.stats.add(Success(octoberDays));
        await settle();
      },
      verify: (cubit) {
        expect(cubit.state.labelsStatus.isFailure, isTrue);
        expect(cubit.state.incomeByCategory.single.label, 'Uncategorised');
      },
    );
  });
}
