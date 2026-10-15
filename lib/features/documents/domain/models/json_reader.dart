import 'package:cloud_firestore/cloud_firestore.dart';

/// Strict field access over a Firestore map.
///
/// Documents are our own schema (written by `issueDocument`), so a missing
/// required field or a wrong type is drift to surface, not absorb: every
/// reader throws a [FormatException] naming the path.
class JsonReader {
  JsonReader(this._map, [this._path = '']);

  final Map<String, dynamic> _map;
  final String _path;

  String _at(String key) => _path.isEmpty ? key : '$_path.$key';

  bool has(String key) => _map[key] != null;

  Iterable<String> get keys => _map.keys;

  String string(String key) {
    final value = _map[key];
    if (value is String) return value;
    throw FormatException('${_at(key)}: expected a string, got $value');
  }

  /// A string that may be absent or null; empty strings are kept.
  String? optionalString(String key) {
    final value = _map[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('${_at(key)}: expected a string, got $value');
  }

  /// A string field where absence means "empty".
  String text(String key) => optionalString(key) ?? '';

  /// Money and quantities are integers. A double that is whole (a JS number
  /// may round-trip as `1.0` on some platforms) is accepted; a fraction is not.
  int integer(String key) {
    final value = _map[key];
    final parsed = _asInt(value);
    if (parsed != null) return parsed;
    throw FormatException('${_at(key)}: expected an integer, got $value');
  }

  int? optionalInt(String key) {
    final value = _map[key];
    if (value == null) return null;
    return integer(key);
  }

  int intOrZero(String key) => optionalInt(key) ?? 0;

  bool boolean(String key, {bool fallback = false}) {
    final value = _map[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    throw FormatException('${_at(key)}: expected a bool, got $value');
  }

  JsonReader map(String key) {
    final value = _map[key];
    if (value is Map) return JsonReader(_cast(value), _at(key));
    throw FormatException('${_at(key)}: expected a map, got $value');
  }

  JsonReader? optionalMap(String key) => _map[key] == null ? null : map(key);

  List<JsonReader> mapList(String key) {
    final value = _map[key];
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('${_at(key)}: expected a list, got $value');
    }
    return [
      for (var i = 0; i < value.length; i++)
        if (value[i] is Map)
          JsonReader(_cast(value[i] as Map), '${_at(key)}[$i]')
        else
          throw FormatException('${_at(key)}[$i]: expected a map'),
    ];
  }

  /// A Firestore `Timestamp`. `null` while a server timestamp is pending in
  /// the local cache.
  DateTime? timestamp(String key) {
    final value = _map[key];
    return switch (value) {
      null => null,
      final Timestamp ts => ts.toDate(),
      final DateTime dt => dt,
      _ => throw FormatException('${_at(key)}: expected a timestamp'),
    };
  }

  static final RegExp _calendarDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// A `yyyy-MM-dd` calendar date.
  String date(String key) {
    final value = string(key);
    if (_calendarDate.hasMatch(value)) return value;
    throw FormatException('${_at(key)}: expected yyyy-MM-dd, got $value');
  }

  String? optionalDate(String key) => _map[key] == null ? null : date(key);

  static int? _asInt(Object? value) => switch (value) {
    final int i => i,
    final double d when d == d.truncateToDouble() && d.isFinite => d.toInt(),
    _ => null,
  };

  static Map<String, dynamic> _cast(Map<dynamic, dynamic> map) =>
      map.map((key, value) => MapEntry('$key', value));
}
