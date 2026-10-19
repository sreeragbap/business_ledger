import 'dart:convert';

/// Typed, forgiving reads from a row map (a Postgres row from Supabase or
/// the same row read back from the local SQLite store, see
/// `core/database/row_codec.dart`).
///
/// Every model's `fromMap` goes through these, so one rule holds everywhere:
/// a missing field or one of the wrong type falls back to a safe default
/// instead of throwing, and fields the app does not know are ignored. A row
/// written by a newer app version (or by the server) can therefore never
/// crash a list.
///
/// Integers are strict about meaning, not shape: `3.0` reads as `3`, `3.5`
/// does not silently become `3` — it falls back, because a truncated amount
/// is a wrong amount.
extension JsonRead on Map<String, dynamic> {
  String readString(String key, [String fallback = '']) {
    final value = this[key];
    return value is String ? value : fallback;
  }

  /// `null` when absent, not a string, or blank.
  String? readOptionalString(String key) {
    final value = this[key];
    if (value is! String) return null;
    return value.trim().isEmpty ? null : value;
  }

  bool readBool(String key, {bool fallback = false}) {
    final value = this[key];
    return value is bool ? value : fallback;
  }

  int readInt(String key, [int fallback = 0]) =>
      readOptionalInt(key) ?? fallback;

  int? readOptionalInt(String key) {
    final value = this[key];
    if (value is int) return value;
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.toInt();
    }
    return null;
  }

  /// An ISO-8601 timestamp (`timestamptz` as PostgREST sends it), or a
  /// [DateTime], as a local [DateTime]. `null` when absent or unparsable,
  /// which is normal for a row created on this device and not synced yet.
  DateTime? readDate(String key) => switch (this[key]) {
    final DateTime value => value.toLocal(),
    final String value => DateTime.tryParse(value)?.toLocal(),
    _ => null,
  };

  /// A JSON array (or its encoded text) of strings; other items are skipped.
  List<String> readStringList(String key) {
    final value = _decoded(this[key]);
    if (value is! List) return const [];
    return List<String>.unmodifiable(value.whereType<String>());
  }

  /// A JSON array (or its encoded text); empty when absent.
  List<Object?> readList(String key) {
    final value = _decoded(this[key]);
    return value is List ? value : const [];
  }

  /// A JSON object (or its encoded text).
  Map<String, dynamic> readMap(String key) {
    final value = _decoded(this[key]);
    if (value is! Map) return const {};
    return value.map((key, inner) => MapEntry('$key', inner));
  }

  static Object? _decoded(Object? value) {
    if (value is! String) return value;
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }
}

/// Postgres rows use snake_case columns; the models' `fromMap` read the
/// camelCase keys the app (and the RPC results) always used.
abstract final class RowKeys {
  static final RegExp _underscore = RegExp('_([a-z0-9])');

  /// `business_id` → `businessId`. Only the top level: JSON columns keep
  /// their own (already camelCase) keys.
  static String camel(String key) =>
      key.replaceAllMapped(_underscore, (match) => match[1]!.toUpperCase());

  /// `businessId` → `business_id`.
  static String snake(String key) => key.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match[0]!.toLowerCase()}',
  );

  /// Every top-level key of [map] in snake_case (a model's `toMap` as a
  /// row).
  static Map<String, Object?> snakeMap(Map<String, Object?> map) => {
    for (final entry in map.entries) snake(entry.key): entry.value,
  };

  /// Every top-level key of [row] in camelCase.
  static Map<String, dynamic> camelMap(Map<String, dynamic> row) => {
    for (final entry in row.entries) camel(entry.key): entry.value,
  };
}
