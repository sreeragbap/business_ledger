import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:intl/intl.dart';

/// Calendar-day helpers for transaction dates (`yyyy-MM-dd`, ARCHITECTURE
/// §3). A transaction date is a day, not an instant.
abstract final class LedgerDates {
  static final RegExp _pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final DateFormat _long = DateFormat('d MMM yyyy', 'en_US');
  static final DateFormat _short = DateFormat('d MMM', 'en_US');
  static final DateFormat _section = DateFormat('EEEE, d MMMM yyyy', 'en_US');

  /// Today on this device as `yyyy-MM-dd`.
  static String today([DateTime? now]) =>
      CalendarDay.key(CalendarDay.today(now));

  static String key(DateTime day) => CalendarDay.key(day);

  /// Whether [value] is a real `yyyy-MM-dd` day (no 2026-02-30), matching
  /// `isCalendarDate` in `functions/src/lib/dates.ts`.
  static bool isValid(String? value) {
    if (value == null || !_pattern.hasMatch(value)) return false;
    final parsed = DateTime.tryParse('${value}T00:00:00Z');
    return parsed != null && CalendarDay.key(parsed) == value;
  }

  /// The day as a UTC midnight, or `null` when [value] is not a valid day.
  static DateTime? parse(String? value) =>
      isValid(value) ? CalendarDay.parse(value!) : null;

  /// `14 Oct 2026`; empty for an invalid day.
  static String format(String? day) {
    final parsed = parse(day);
    return parsed == null ? '' : _long.format(parsed);
  }

  /// `14 Oct`.
  static String formatShort(String? day) {
    final parsed = parse(day);
    return parsed == null ? '' : _short.format(parsed);
  }

  /// Section heading in the list: Today, Yesterday, or the full date.
  static String sectionLabel(String? day, String today) {
    final parsed = parse(day);
    if (parsed == null) return 'No date';
    if (day == today) return 'Today';
    final yesterday = CalendarDay.key(
      CalendarDay.addDays(CalendarDay.parse(today), -1),
    );
    if (day == yesterday) return 'Yesterday';
    return _section.format(parsed);
  }
}
