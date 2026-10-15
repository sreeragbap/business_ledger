import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

enum DateRangePreset {
  today('Today'),
  thisWeek('This week'),
  thisMonth('This month'),
  lastMonth('Last month'),
  thisYear('This year'),
  custom('Custom');

  const DateRangePreset(this.label);
  final String label;
}

/// An inclusive range of calendar days.
class ReportRange extends Equatable {
  const ReportRange._(this.preset, this.from, this.to);

  /// [from] and [to] in either order; both inclusive.
  factory ReportRange.custom(DateTime from, DateTime to) {
    final a = CalendarDay.of(from);
    final b = CalendarDay.of(to);
    return a.isAfter(b)
        ? ReportRange._(DateRangePreset.custom, b, a)
        : ReportRange._(DateRangePreset.custom, a, b);
  }

  /// The whole period containing [today]: this week runs Monday to Sunday,
  /// this month to its last day. Days after today are simply empty.
  factory ReportRange.preset(DateRangePreset preset, DateTime today) {
    final day = CalendarDay.of(today);
    return switch (preset) {
      DateRangePreset.today => ReportRange._(preset, day, day),
      DateRangePreset.thisWeek => ReportRange._(
        preset,
        CalendarDay.weekStart(day),
        CalendarDay.addDays(CalendarDay.weekStart(day), 6),
      ),
      DateRangePreset.thisMonth => ReportRange._(
        preset,
        CalendarDay.monthStart(day),
        CalendarDay.monthEnd(day),
      ),
      DateRangePreset.lastMonth => ReportRange._(
        preset,
        DateTime.utc(day.year, day.month - 1),
        DateTime.utc(day.year, day.month, 0),
      ),
      DateRangePreset.thisYear => ReportRange._(
        preset,
        DateTime.utc(day.year),
        DateTime.utc(day.year, 12, 31),
      ),
      DateRangePreset.custom => ReportRange._(preset, day, day),
    };
  }

  final DateRangePreset preset;

  /// UTC midnight of the first day.
  final DateTime from;

  /// UTC midnight of the last day (inclusive).
  final DateTime to;

  String get fromKey => CalendarDay.key(from);
  String get toKey => CalendarDay.key(to);
  int get days => CalendarDay.span(from, to);

  bool contains(String dayKey) =>
      dayKey.compareTo(fromKey) >= 0 && dayKey.compareTo(toKey) <= 0;

  /// `1 – 31 Oct 2026`, `14 Oct 2026`, `28 Sep – 4 Oct 2026`.
  String get label {
    final full = DateFormat('d MMM yyyy', 'en_US');
    if (from == to) return full.format(from);
    if (from.year != to.year) {
      return '${full.format(from)} – ${full.format(to)}';
    }
    if (from.month != to.month) {
      return '${DateFormat('d MMM', 'en_US').format(from)} – '
          '${full.format(to)}';
    }
    return '${from.day} – ${full.format(to)}';
  }

  /// The preset's name, or the dates for a custom range.
  String get title => preset == DateRangePreset.custom ? label : preset.label;

  @override
  List<Object?> get props => [preset, from, to];

  @override
  String toString() => 'ReportRange(${preset.name}: $fromKey..$toKey)';
}
