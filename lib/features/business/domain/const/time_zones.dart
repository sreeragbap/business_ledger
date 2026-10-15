/// Time zones offered when creating or editing a business.
///
/// The business time zone decides which calendar day "today" is for due
/// dates and daily stats. The list is short on purpose; [deviceDefault]
/// guesses the device's zone without a plugin.
abstract final class TimeZones {
  static const String fallback = 'Asia/Kolkata';

  /// IANA name → standard UTC offset in minutes (ignoring daylight saving).
  static const Map<String, int> common = {
    'Asia/Kolkata': 330,
    'Asia/Dubai': 240,
    'Asia/Riyadh': 180,
    'Asia/Kuwait': 180,
    'Asia/Singapore': 480,
    'Asia/Tokyo': 540,
    'Asia/Karachi': 300,
    'Asia/Dhaka': 360,
    'Asia/Kathmandu': 345,
    'Asia/Colombo': 330,
    'Europe/London': 0,
    'Europe/Berlin': 60,
    'Africa/Nairobi': 180,
    'America/New_York': -300,
    'America/Chicago': -360,
    'America/Los_Angeles': -480,
    'Australia/Sydney': 600,
    'UTC': 0,
  };

  static List<String> get names => common.keys.toList(growable: false);

  /// The device's zone when it can be named, else [fallback].
  ///
  /// Dart exposes only an abbreviation (`IST`) or, on some platforms, an IANA
  /// name. An IANA-looking name is used as is; otherwise the first listed
  /// zone with the device's current offset is chosen. Under daylight saving
  /// the offset can match no standard offset, and [fallback] is used.
  static String deviceDefault([DateTime? now]) {
    final at = now ?? DateTime.now();
    final name = at.timeZoneName;
    if (name.contains('/')) return name;
    final offset = at.timeZoneOffset.inMinutes;
    for (final entry in common.entries) {
      if (entry.value == offset && entry.key != 'UTC') return entry.key;
    }
    return offset == 0 ? 'UTC' : fallback;
  }

  /// [names] with [current] included, for a picker that must show the stored
  /// value even when it is not in the short list.
  static List<String> optionsIncluding(String? current) => [
    if (current != null && current.isNotEmpty && !common.containsKey(current))
      current,
    ...names,
  ];

  /// `Asia/Kolkata (UTC+05:30)`.
  static String label(String name) {
    final minutes = common[name];
    if (minutes == null) return name;
    final sign = minutes < 0 ? '-' : '+';
    final abs = minutes.abs();
    final hours = (abs ~/ 60).toString().padLeft(2, '0');
    final mins = (abs % 60).toString().padLeft(2, '0');
    return '$name (UTC$sign$hours:$mins)';
  }
}
