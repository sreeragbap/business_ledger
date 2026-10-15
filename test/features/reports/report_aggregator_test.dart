import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/logic/report_aggregator.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/report_scope.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

DailyStats day(
  String date, {
  int income = 0,
  int expense = 0,
  int cashIn = 0,
  int cashOut = 0,
  Map<String, InOut> byCategory = const {},
  Map<String, InOut> byProject = const {},
  Map<String, InOut> byType = const {},
}) => DailyStats(
  date: date,
  incomeMinor: income,
  expenseMinor: expense,
  cashInMinor: cashIn,
  cashOutMinor: cashOut,
  byCategory: byCategory,
  byProject: byProject,
  byType: byType,
);

ReportRange range(String from, String to) =>
    ReportRange.custom(CalendarDay.parse(from), CalendarDay.parse(to));

void main() {
  group('sum', () {
    final days = [
      day(
        '2026-10-01',
        income: 100000,
        expense: 25000,
        cashIn: 40000,
        byCategory: {
          'c1': const InOut(inMinor: 100000),
          'c2': const InOut(outMinor: 25000),
        },
        byType: {'sale': const InOut(inMinor: 100000)},
      ),
      day(
        '2026-10-02',
        income: 5000,
        expense: 80000,
        cashOut: 80000,
        byCategory: {
          'c1': const InOut(inMinor: 5000),
          'c2': const InOut(outMinor: 80000),
        },
      ),
      day('2026-11-01', income: 999),
    ];

    test('adds every figure and keeps cash apart from income', () {
      final totals = ReportAggregator.sum(days.take(2));
      expect(totals.incomeMinor, 105000);
      expect(totals.expenseMinor, 105000);
      expect(totals.netMinor, 0);
      expect(totals.cashInMinor, 40000);
      expect(totals.cashOutMinor, 80000);
      expect(totals.netCashMinor, -40000);
      expect(totals.byCategory['c1'], const InOut(inMinor: 105000));
      expect(totals.byCategory['c2'], const InOut(outMinor: 105000));
      expect(totals.byType['sale'], const InOut(inMinor: 100000));
      expect(totals.days, 2);
    });

    test('drops days outside the range', () {
      final totals = ReportAggregator.sum(
        days,
        range: range('2026-10-01', '2026-10-31'),
      );
      expect(totals.incomeMinor, 105000);
      expect(totals.days, 2);
    });

    test('a scope reads its slice and zeroes cash', () {
      const scope = ReportScope(
        dimension: ReportDimension.category,
        id: 'c2',
        label: 'Rent',
      );
      final totals = ReportAggregator.sum(days, scope: scope);
      expect(totals.incomeMinor, 0);
      expect(totals.expenseMinor, 105000);
      expect(totals.cashInMinor, 0);
      expect(totals.cashOutMinor, 0);
    });

    test('nothing sums to zero', () {
      expect(ReportAggregator.sum(const []).isEmpty, isTrue);
    });
  });

  group('series', () {
    test('daily fills empty days with zero', () {
      final series = ReportAggregator.series(
        [day('2026-10-02', income: 7), day('2026-10-04', expense: 3)],
        range: range('2026-10-01', '2026-10-05'),
        granularity: ReportGranularity.daily,
      );
      expect(series.map((b) => b.incomeMinor), [0, 7, 0, 0, 0]);
      expect(series.map((b) => b.expenseMinor), [0, 0, 0, 3, 0]);
      expect(series.first.label, '1 Oct');
    });

    test('weekly buckets start on Monday, across a month boundary', () {
      // 2026-09-28 is a Monday; 2026-10-05 is the next one.
      final series = ReportAggregator.series(
        [
          day('2026-09-30', income: 1),
          day('2026-10-04', income: 2), // Sunday, same week
          day('2026-10-05', income: 4), // Monday, next week
          day('2026-10-14', cashIn: 8),
        ],
        range: range('2026-09-30', '2026-10-14'),
        granularity: ReportGranularity.weekly,
      );
      expect(series.map((b) => CalendarDay.key(b.start)), [
        '2026-09-28',
        '2026-10-05',
        '2026-10-12',
      ]);
      expect(series.map((b) => CalendarDay.key(b.end)), [
        '2026-10-04',
        '2026-10-11',
        '2026-10-18',
      ]);
      expect(series.map((b) => b.incomeMinor), [3, 4, 0]);
      expect(series.map((b) => b.cashInMinor), [0, 0, 8]);
    });

    test('weekly buckets across a year boundary (ISO week from Monday)', () {
      // 2026-12-28 is a Monday; its week runs into 2027.
      final series = ReportAggregator.series(
        [day('2026-12-31', income: 5), day('2027-01-03', income: 6)],
        range: range('2026-12-25', '2027-01-06'),
        granularity: ReportGranularity.weekly,
      );
      expect(series.map((b) => CalendarDay.key(b.start)), [
        '2026-12-21',
        '2026-12-28',
        '2027-01-04',
      ]);
      expect(series.map((b) => b.incomeMinor), [0, 11, 0]);
    });

    test('days outside the range are ignored even inside a shown week', () {
      final series = ReportAggregator.series(
        [day('2026-09-28', income: 100), day('2026-09-30', income: 1)],
        range: range('2026-09-30', '2026-10-01'),
        granularity: ReportGranularity.weekly,
      );
      expect(series.single.incomeMinor, 1);
    });

    test('monthly across a year boundary, with empty months', () {
      final series = ReportAggregator.series(
        [
          day('2026-11-30', income: 1),
          day('2026-12-01', income: 2),
          day('2026-12-31', expense: 3),
          day('2027-02-28', income: 4),
        ],
        range: range('2026-11-15', '2027-02-28'),
        granularity: ReportGranularity.monthly,
      );
      expect(series.map((b) => b.label), [
        'Nov 26',
        'Dec 26',
        'Jan 27',
        'Feb 27',
      ]);
      expect(series.map((b) => b.incomeMinor), [1, 2, 0, 4]);
      expect(series.map((b) => b.expenseMinor), [0, 3, 0, 0]);
      expect(CalendarDay.key(series[2].end), '2027-01-31');
      expect(CalendarDay.key(series[3].end), '2027-02-28');
    });

    test('a scoped series uses the slice', () {
      final series = ReportAggregator.series(
        [
          day(
            '2026-10-01',
            income: 50,
            cashIn: 50,
            byProject: {'p1': const InOut(inMinor: 20, outMinor: 5)},
          ),
        ],
        range: range('2026-10-01', '2026-10-01'),
        granularity: ReportGranularity.daily,
        scope: const ReportScope(
          dimension: ReportDimension.project,
          id: 'p1',
          label: 'Fit-out',
        ),
      );
      expect(
        series.single,
        isA<StatsBucket>()
            .having((b) => b.incomeMinor, 'income', 20)
            .having((b) => b.expenseMinor, 'expense', 5)
            .having((b) => b.cashInMinor, 'cash', 0),
      );
    });

    test('default granularity follows the range length', () {
      expect(
        ReportAggregator.defaultGranularity(range('2026-10-01', '2026-10-31')),
        ReportGranularity.daily,
      );
      expect(
        ReportAggregator.defaultGranularity(range('2026-08-01', '2026-10-31')),
        ReportGranularity.weekly,
      );
      expect(
        ReportAggregator.defaultGranularity(range('2026-01-01', '2026-12-31')),
        ReportGranularity.monthly,
      );
    });
  });

  group('breakdown and basis points', () {
    test('shares sum to exactly 10000 by largest remainder', () {
      final shares = ReportAggregator.basisPoints([1, 1, 1]);
      expect(shares, [3334, 3333, 3333]);
      expect(shares.reduce((a, b) => a + b), 10000);

      final uneven = ReportAggregator.basisPoints([2, 3, 7, 11, 13]);
      expect(uneven.reduce((a, b) => a + b), 10000);
    });

    test('zero total gives zero shares; negatives count as zero', () {
      expect(ReportAggregator.basisPoints([0, 0]), [0, 0]);
      expect(ReportAggregator.basisPoints([-5, 5]), [0, 10000]);
      expect(ReportAggregator.basisPoints(const []), isEmpty);
    });

    test('large amounts stay exact', () {
      final shares = ReportAggregator.basisPoints([
        9000000000000,
        1000000000000,
      ]);
      expect(shares, [9000, 1000]);
    });

    test('breakdown is sorted desc, labelled, and skips empty sides', () {
      final entries = ReportAggregator.breakdown(
        {
          'c1': const InOut(inMinor: 2500, outMinor: 10),
          'c2': const InOut(inMinor: 7500),
          'c3': const InOut(outMinor: 400),
          'gone': InOut.zero,
        },
        side: Direction.inflow,
        labels: {'c1': 'Services', 'c2': 'Sales'},
      );
      expect(entries.map((e) => (e.label, e.amountMinor, e.shareBasisPoints)), [
        ('Sales', 7500, 7500),
        ('Services', 2500, 2500),
      ]);
      expect(entries.first.sharePercent, '75%');
    });

    test('unknown ids use the fallback label; ties sort by label', () {
      final entries = ReportAggregator.breakdown(
        {'x': const InOut(outMinor: 1), 'a': const InOut(outMinor: 1)},
        side: Direction.outflow,
        labels: {'a': 'Zeta'},
      );
      expect(entries.map((e) => e.label), ['Other', 'Zeta']);
      expect(entries.first.sharePercent, '50%');
    });

    test('sharePercent shows one decimal', () {
      const entry = BreakdownEntry(
        id: 'x',
        label: 'x',
        amountMinor: 1,
        shareBasisPoints: 3333,
      );
      expect(entry.sharePercent, '33.3%');
    });
  });
}
