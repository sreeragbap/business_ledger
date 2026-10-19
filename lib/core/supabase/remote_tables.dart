import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The PostgREST table calls the sync engine makes, behind an interface the
/// app owns so tests run without a network. Every method throws what the
/// client throws (`PostgrestException`, socket errors, timeouts); callers
/// map it with `AppException.from`.
abstract class RemoteTables {
  const RemoteTables();

  /// Rows of [table] changed after [afterSeq], in `seq` order, at most
  /// [limit]. With [businessId], only that business's rows
  /// (`supabase/README.md`, Sync).
  Future<List<Map<String, dynamic>>> changes(
    String table, {
    required int afterSeq,
    required int limit,
    String? businessId,
  });

  /// Every row of [table] the caller may read, filtered by [equals].
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, Object> equals = const {},
  });

  /// Inserts or updates [rows] by primary key.
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Sets [values] on the rows matching [match]. Returns how many rows the
  /// server changed: 0 means row level security refused it (or the row is
  /// gone), which PostgREST does not report as an error.
  Future<int> update(
    String table,
    Map<String, Object> match,
    Map<String, Object?> values,
  );
}

@LazySingleton(as: RemoteTables)
class SupabaseRemoteTables extends RemoteTables {
  const SupabaseRemoteTables(this._client);

  final SupabaseClient _client;

  /// Per request. A page of 500 rows is small; a slow link gets this long.
  static const Duration timeout = Duration(seconds: 30);

  @override
  Future<List<Map<String, dynamic>>> changes(
    String table, {
    required int afterSeq,
    required int limit,
    String? businessId,
  }) async {
    var query = _client.from(table).select().gt('seq', afterSeq);
    if (businessId != null) query = query.eq('business_id', businessId);
    return query.order('seq', ascending: true).limit(limit).timeout(timeout);
  }

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, Object> equals = const {},
  }) async {
    var query = _client.from(table).select();
    for (final entry in equals.entries) {
      query = query.eq(entry.key, entry.value);
    }
    return query.timeout(timeout);
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    // `missing=default`: a column a row leaves out keeps its default (or,
    // on update, its value) instead of becoming null.
    await _client
        .from(table)
        .upsert(rows, defaultToNull: false)
        .timeout(timeout);
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object> match,
    Map<String, Object?> values,
  ) async {
    final rows = await _client
        .from(table)
        .update(values)
        .match(match)
        .select()
        .timeout(timeout);
    return rows.length;
  }
}
