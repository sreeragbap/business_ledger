import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/report_scope.dart';
import 'package:business_ledger/features/reports/domain/models/stats_bucket.dart';
import 'package:business_ledger/features/reports/domain/models/stats_totals.dart';
import 'package:intl/intl.dart';

/// Sums and buckets daily stats. Pure and integer-only: no money here is
/// ever a double (doubles appear later, in chart geometry only).
abstract final class ReportAggregator {
  static const int fullShare = 10000;

  /// Sums [days], keeping only those inside [range] when given.
  ///
  /// With a [scope], income and expense are that slice's in/out and cash is
  /// zero, because the server does not split cash by dimension.
  static StatsTotals sum(
    Iterable<DailyStats> days, {
    ReportRange? range,
    ReportScope? scope,
  }) {
    var income = 0;
    var expense = 0;
    var cashIn = 0;
    var cashOut = 0;
    var count = 0;
    final byCategory = <String, InOut>{};
    final byProject = <String, InOut>{};
    final byType = <String, InOut>{};

    for (final day in days) {
      if (range != null && !range.contains(day.date)) continue;
      count++;
      if (scope != null) {
        final slice = scope.of(day);
        income += slice.inMinor;
        expense += slice.outMinor;
      } else {
        income += day.incomeMinor;
        expense += day.expenseMinor;
        cashIn += day.cashInMinor;
        cashOut += day.cashOutMinor;
      }
      _merge(byCategory, day.byCategory);
      _merge(byProject, day.byProject);
      _merge(byType, day.byType);
    }

    return StatsTotals(
      incomeMinor: income,
      expenseMinor: expense,
      cashInMinor: cashIn,
      cashOutMinor: cashOut,
      byCategory: byCategory,
      byProject: byProject,
      byType: byType,
      days: count,
    );
  }

  static void _merge(Map<String, InOut> into, Map<String, InOut> from) {
    for (final MapEntry(:key, :value) in from.entries) {
      into[key] = (into[key] ?? InOut.zero) + value;
    }
  }

  /// A sensible default: days up to a month, weeks up to ~4 months, then
  /// months.
  static ReportGranularity defaultGranularity(ReportRange range) =>
      switch (range.days) {
        <= 31 => ReportGranularity.daily,
        <= 120 => ReportGranularity.weekly,
        _ => ReportGranularity.monthly,
      };

  /// One bucket per day / ISO week / month touching [range], in order, with
  /// empty buckets filled with zeros. Days outside [range] are ignored even
  /// when their week or month is shown.
  static List<StatsBucket> series(
    Iterable<DailyStats> days, {
    required ReportRange range,
    required ReportGranularity granularity,
    ReportScope? scope,
  }) {
    final starts = bucketStarts(range, granularity);
    final index = {
      for (var i = 0; i < starts.length; i++) CalendarDay.key(starts[i]): i,
    };
    final income = List.filled(starts.length, 0);
    final expense = List.filled(starts.length, 0);
    final cashIn = List.filled(starts.length, 0);
    final cashOut = List.filled(starts.length, 0);

    for (final day in days) {
      if (!range.contains(day.date)) continue;
      final start = _bucketStart(CalendarDay.parse(day.date), granularity);
      final i = index[CalendarDay.key(start)];
      if (i == null) continue;
      if (scope != null) {
        final slice = scope.of(day);
        income[i] += slice.inMinor;
        expense[i] += slice.outMinor;
      } else {
        income[i] += day.incomeMinor;
        expense[i] += day.expenseMinor;
        cashIn[i] += day.cashInMinor;
        cashOut[i] += day.cashOutMinor;
      }
    }

    final crossesYears = range.from.year != range.to.year;
    return [
      for (var i = 0; i < starts.length; i++)
        StatsBucket(
          start: starts[i],
          end: _bucketEnd(starts[i], granularity),
          label: _label(starts[i], granularity, crossesYears: crossesYears),
          incomeMinor: income[i],
          expenseMinor: expense[i],
          cashInMinor: cashIn[i],
          cashOutMinor: cashOut[i],
        ),
    ];
  }

  /// The first day of every bucket overlapping [range].
  static List<DateTime> bucketStarts(
    ReportRange range,
    ReportGranularity granularity,
  ) {
    final starts = <DateTime>[];
    var cursor = _bucketStart(range.from, granularity);
    while (!cursor.isAfter(range.to)) {
      starts.add(cursor);
      cursor = CalendarDay.addDays(_bucketEnd(cursor, granularity), 1);
    }
    return starts;
  }

  static DateTime _bucketStart(DateTime day, ReportGranularity granularity) =>
      switch (granularity) {
        ReportGranularity.daily => CalendarDay.of(day),
        ReportGranularity.weekly => CalendarDay.weekStart(day),
        ReportGranularity.monthly => CalendarDay.monthStart(day),
      };

  static DateTime _bucketEnd(DateTime start, ReportGranularity granularity) =>
      switch (granularity) {
        ReportGranularity.daily => start,
        ReportGranularity.weekly => CalendarDay.addDays(start, 6),
        ReportGranularity.monthly => CalendarDay.monthEnd(start),
      };

  static String _label(
    DateTime start,
    ReportGranularity granularity, {
    required bool crossesYears,
  }) => switch (granularity) {
    ReportGranularity.daily || ReportGranularity.weekly => DateFormat(
      'd MMM',
      'en_US',
    ).format(start),
    ReportGranularity.monthly => DateFormat(
      crossesYears ? 'MMM yy' : 'MMM',
      'en_US',
    ).format(start),
  };

  /// Entries for one side of [slices] (in for income, out for expense),
  /// largest first, with zero and negative amounts left out. Names come
  /// from [labels]; an unknown id shows [unknownLabel].
  static List<BreakdownEntry> breakdown(
    Map<String, InOut> slices, {
    required Direction side,
    Map<String, String> labels = const {},
    String unknownLabel = 'Other',
  }) {
    final rows =
        <(String, String, int)>[
          for (final MapEntry(:key, :value) in slices.entries)
            if (_side(value, side) > 0)
              (key, labels[key] ?? unknownLabel, _side(value, side)),
        ]..sort((a, b) {
          final byAmount = b.$3.compareTo(a.$3);
          return byAmount != 0 ? byAmount : a.$2.compareTo(b.$2);
        });
    final shares = basisPoints([for (final row in rows) row.$3]);
    return [
      for (var i = 0; i < rows.length; i++)
        BreakdownEntry(
          id: rows[i].$1,
          label: rows[i].$2,
          amountMinor: rows[i].$3,
          shareBasisPoints: shares[i],
        ),
    ];
  }

  static int _side(InOut value, Direction side) =>
      side == Direction.inflow ? value.inMinor : value.outMinor;

  /// Each amount's share of their total in basis points, by the largest
  /// remainder method, so the shares sum to exactly [fullShare] whenever the
  /// total is positive. Negative amounts count as zero.
  static List<int> basisPoints(List<int> amounts) {
    final clamped = [for (final a in amounts) a < 0 ? 0 : a];
    final total = clamped.fold<int>(0, (sum, a) => sum + a);
    if (total == 0) return List.filled(amounts.length, 0);

    final shares = <int>[];
    final remainders = <(int index, int remainder)>[];
    var allocated = 0;
    for (var i = 0; i < clamped.length; i++) {
      // Integer floor of a * 10000 / total; amounts stay far below 2^63 / 10^4.
      final scaled = clamped[i] * fullShare;
      shares.add(scaled ~/ total);
      remainders.add((i, scaled % total));
      allocated += shares[i];
    }
    remainders.sort((a, b) {
      final byRemainder = b.$2.compareTo(a.$2);
      return byRemainder != 0 ? byRemainder : a.$1.compareTo(b.$1);
    });
    for (var k = 0; k < fullShare - allocated; k++) {
      shares[remainders[k].$1]++;
    }
    return shares;
  }
}
