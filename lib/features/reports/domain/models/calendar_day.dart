import 'package:intl/intl.dart';

/// Calendar-day arithmetic over UTC midnights.
///
/// Ledger dates are days (`yyyy-MM-dd`), not instants (ARCHITECTURE §3).
/// Using UTC for the arithmetic keeps daylight-saving changes from turning a
/// day into 23 or 25 hours.
abstract final class CalendarDay {
  static final DateFormat _key = DateFormat('yyyy-MM-dd', 'en_US');

  /// The date part of [moment], as a UTC midnight.
  static DateTime of(DateTime moment) =>
      DateTime.utc(moment.year, moment.month, moment.day);

  /// Today on this device.
  static DateTime today([DateTime? now]) => of(now ?? DateTime.now());

  /// `2026-10-14`.
  static String key(DateTime day) => _key.format(of(day));

  /// Parses `yyyy-MM-dd` into a UTC midnight.
  static DateTime parse(String key) {
    final parts = key.split('-');
    if (parts.length != 3) throw FormatException('Not a calendar day: $key');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static DateTime addDays(DateTime day, int days) =>
      DateTime.utc(day.year, day.month, day.day + days);

  /// The Monday of [day]'s ISO week.
  static DateTime weekStart(DateTime day) =>
      addDays(of(day), -(day.weekday - DateTime.monday));

  static DateTime monthStart(DateTime day) => DateTime.utc(day.year, day.month);

  /// Last day of [day]'s month (day 0 of the next month).
  static DateTime monthEnd(DateTime day) =>
      DateTime.utc(day.year, day.month + 1, 0);

  /// Inclusive count of days from [from] to [to].
  static int span(DateTime from, DateTime to) =>
      of(to).difference(of(from)).inDays + 1;
}
