import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/supabase/remote_rpc.dart';
import 'package:business_ledger/core/supabase/remote_tables.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// A fresh on-device store in memory.
LocalStore memoryStore() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return LocalStore(AppDatabase(NativeDatabase.memory()));
}

/// Supabase's tables in memory, with the behaviour the sync engine relies
/// on: a global `seq` stamped on every insert and update, PostgREST upsert
/// by primary key, and an UPDATE that RLS refuses changing nothing.
class FakeRemoteTables extends RemoteTables {
  final Map<String, List<Map<String, dynamic>>> tables = {};

  /// Every call, e.g. `changes members b1 >0 #500`, `upsert categories`.
  final List<String> calls = [];

  /// Thrown by the next call (then cleared).
  Exception? failNext;

  /// Tables whose writes row level security refuses: an upsert throws
  /// `42501`, an update changes nothing.
  final Set<String> refuse = {};

  /// Businesses the caller is a member of (`select businesses`); all when
  /// `null`.
  Set<String>? memberOf;

  int _seq = 0;

  List<Map<String, dynamic>> rows(String table) => tables[table] ??= [];

  /// Adds (or replaces) a server row, stamping `seq` unless given.
  Map<String, dynamic> seed(String table, Map<String, dynamic> row) {
    final stamped = {...row, 'seq': row['seq'] ?? ++_seq};
    if (stamped['seq'] case final int seq when seq > _seq) _seq = seq;
    _put(table, stamped);
    return stamped;
  }

  void _put(String table, Map<String, dynamic> row) {
    final keys = SyncTable.byName(table).keys;
    final list = rows(table);
    final index = list.indexWhere(
      (existing) => keys.every((key) => existing[key] == row[key]),
    );
    if (index < 0) {
      list.add(row);
    } else {
      list[index] = row;
    }
  }

  void _maybeFail() {
    final error = failNext;
    if (error != null) {
      failNext = null;
      throw error;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> changes(
    String table, {
    required int afterSeq,
    required int limit,
    String? businessId,
  }) async {
    calls.add('changes $table ${businessId ?? '-'} >$afterSeq #$limit');
    _maybeFail();
    final matching =
        rows(table)
            .where(
              (row) =>
                  (row['seq'] as int) > afterSeq &&
                  (businessId == null || row['business_id'] == businessId),
            )
            .toList()
          ..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));
    return [for (final row in matching.take(limit)) Map.of(row)];
  }

  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, Object> equals = const {},
  }) async {
    calls.add('select $table');
    _maybeFail();
    return [
      for (final row in rows(table))
        if (equals.entries.every((e) => row[e.key] == e.value) &&
            (table != 'businesses' ||
                memberOf == null ||
                memberOf!.contains(row['id'])))
          Map.of(row),
    ];
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    calls.add('upsert $table');
    _maybeFail();
    if (refuse.contains(table)) {
      throw const PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );
    }
    final keys = SyncTable.byName(table).keys;
    for (final row in rows) {
      final existing = this
          .rows(table)
          .where(
            (candidate) => keys.every((key) => candidate[key] == row[key]),
          );
      _put(table, {
        if (existing.isNotEmpty) ...existing.first,
        ...row,
        'seq': ++_seq,
      });
    }
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object> match,
    Map<String, Object?> values,
  ) async {
    calls.add('update $table');
    _maybeFail();
    if (refuse.contains(table)) return 0;
    var changed = 0;
    final list = rows(table);
    for (var i = 0; i < list.length; i++) {
      if (match.entries.every((e) => list[i][e.key] == e.value)) {
        list[i] = {...list[i], ...values, 'seq': ++_seq};
        changed++;
      }
    }
    return changed;
  }
}

/// Records RPC calls; answers from [answers] (per function, in order), an
/// empty object otherwise.
class FakeRemoteRpc extends RemoteRpc {
  final List<(String, Map<String, Object?>)> calls = [];
  final Map<String, List<Object? Function()>> answers = {};

  void answer(String function, Object? Function() result) =>
      (answers[function] ??= []).add(result);

  @override
  Future<Object?> call(String function, Map<String, Object?> params) async {
    calls.add((function, params));
    final queue = answers[function];
    if (queue == null || queue.isEmpty) return <String, Object?>{};
    return queue.removeAt(0)();
  }
}
