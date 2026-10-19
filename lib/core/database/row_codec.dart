import 'dart:convert';

import 'package:drift/drift.dart';

/// How rows move between Postgres (PostgREST JSON), the local SQLite store
/// and the models.
///
/// One shape everywhere: a row is a `Map<String, dynamic>` keyed by the
/// snake_case column names (drift is configured with
/// `use_sql_column_name_as_json_key`), with
///
/// * `uuid`, `text`, `date` and `timestamptz` columns as strings (ISO-8601);
/// * `bigint` / `integer` money and counters as `int` (minor units, never a
///   double);
/// * `jsonb` objects as `Map<String, dynamic>` and `jsonb` arrays / `text[]`
///   / `uuid[]` as `List<dynamic>`, stored locally as JSON text.
///
/// A pulled row becomes a drift data class through `fromJson(row,
/// serializer: RowCodec.serializer)`, and a stored one turns back into the
/// same map through `toJson(serializer: RowCodec.serializer)`, so every
/// model parses one format, whatever the source.
abstract final class RowCodec {
  static const ValueSerializer serializer = _RowSerializer();
}

/// Lenient like the models' readers: a column missing from the map (a row
/// built on the device, or a server that has not got a new column yet)
/// becomes its zero value instead of throwing.
class _RowSerializer extends ValueSerializer {
  const _RowSerializer();

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) {
      if (null is T) return null as T;
      if (0 is T) return 0 as T;
      if ('' is T) return '' as T;
      if (false is T) return false as T;
      // Converters handle null themselves (`J` is `Object?`).
      return null as T;
    }
    if (json is T) return json;
    if (json is num && 0 is T) {
      // PostgREST numbers are ints; a whole double (rare) is accepted.
      return json.toInt() as T;
    }
    if ('' is T) {
      return (json is Map || json is List ? jsonEncode(json) : '$json') as T;
    }
    if (json is String && 0 is T) return int.parse(json) as T;
    return json as T;
  }

  @override
  dynamic toJson<T>(T value) => value;
}

/// A `jsonb` object column, stored as JSON text.
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String>
    with JsonTypeConverter2<Map<String, dynamic>, String, Object?> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) => fromJson(fromDb);

  @override
  String toSql(Map<String, dynamic> value) => jsonEncode(value);

  @override
  Map<String, dynamic> fromJson(Object? json) {
    final value = json is String ? _decode(json) : json;
    if (value is! Map) return const {};
    return value.map((key, inner) => MapEntry('$key', inner));
  }

  @override
  Object? toJson(Map<String, dynamic> value) => value;
}

/// A `jsonb` array or a Postgres array column, stored as JSON text.
class JsonListConverter extends TypeConverter<List<dynamic>, String>
    with JsonTypeConverter2<List<dynamic>, String, Object?> {
  const JsonListConverter();

  @override
  List<dynamic> fromSql(String fromDb) => fromJson(fromDb);

  @override
  String toSql(List<dynamic> value) => jsonEncode(value);

  @override
  List<dynamic> fromJson(Object? json) {
    final value = json is String ? _decode(json) : json;
    return value is List ? value : const [];
  }

  @override
  Object? toJson(List<dynamic> value) => value;
}

Object? _decode(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}
