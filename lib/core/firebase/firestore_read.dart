import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed, forgiving reads from a Firestore document map.
///
/// Every model's `fromMap` goes through these, so one rule holds everywhere:
/// a missing field or one of the wrong type falls back to a safe default
/// instead of throwing, and fields the app does not know are ignored. A
/// document written by a newer app version (or seeded by a function) can
/// therefore never crash a list.
///
/// Integers are strict about meaning, not shape: `3.0` reads as `3` (the
/// JavaScript SDK may write integral doubles), `3.5` does not silently become
/// `3` — it falls back, because a truncated amount is a wrong amount.
extension FirestoreRead on Map<String, dynamic> {
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

  /// A Firestore [Timestamp] (or a [DateTime], as written by tests and the
  /// local cache) as a local [DateTime]. `null` while a server timestamp is
  /// still pending, which is normal right after an offline write.
  DateTime? readDate(String key) => switch (this[key]) {
    final Timestamp value => value.toDate(),
    final DateTime value => value,
    _ => null,
  };

  List<String> readStringList(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return List<String>.unmodifiable(value.whereType<String>());
  }

  Map<String, dynamic> readMap(String key) {
    final value = this[key];
    if (value is! Map) return const {};
    return value.map((key, inner) => MapEntry('$key', inner));
  }
}
