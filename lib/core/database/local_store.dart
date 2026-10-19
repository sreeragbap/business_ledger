import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

/// Table-generic access to the on-device store, for the sync engine and the
/// local writes the services make (feature queries live in the services).
///
/// Rows are row maps (`RowCodec`). Every write here notifies drift's stream
/// queries, so screens watching a table update at once.
@lazySingleton
class LocalStore {
  LocalStore(this.db);

  final AppDatabase db;

  static const String _ownerKey = 'owner_uid';
  static const String _pulledKey = 'pulled_at';

  // --- Rows ------------------------------------------------------------------

  /// Inserts or replaces [rows] of [table] by primary key.
  Future<void> upsertRows(
    SyncTable table,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    final list = [for (final row in rows) table.insertable(row)];
    if (list.isEmpty) return;
    await db.batch(
      (batch) => batch.insertAllOnConflictUpdate(table.info(db), list),
    );
  }

  /// The row of [table] with primary key [key], or `null`.
  Future<Map<String, dynamic>?> readRow(
    SyncTable table,
    Map<String, Object?> key,
  ) async {
    final info = table.info(db);
    final result = await db
        .customSelect(
          'SELECT * FROM ${table.name} WHERE ${_where(table)}',
          variables: _variables(table, key),
          readsFrom: {info},
        )
        .getSingleOrNull();
    if (result == null) return null;
    return rowOf(await info.map(result.data));
  }

  Future<void> deleteRow(SyncTable table, Map<String, Object?> key) async {
    await db.customUpdate(
      'DELETE FROM ${table.name} WHERE ${_where(table)}',
      variables: _variables(table, key),
      updates: {table.info(db)},
      updateKind: UpdateKind.delete,
    );
  }

  /// A change made on this device: [values] merged over the stored row (or,
  /// for a new row, over the zero values), marked `local_pending` until the
  /// outbox has pushed it.
  Future<Map<String, dynamic>> writeLocal(
    SyncTable table,
    Map<String, Object?> values,
  ) async {
    final key = table.keyOf(values);
    final existing = await readRow(table, key);
    final merged = <String, dynamic>{
      ...?existing,
      if (existing == null)
        'created_at': DateTime.now().toUtc().toIso8601String(),
      ...values,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (table.writable) 'local_pending': true,
    };
    await upsertRows(table, [merged]);
    return merged;
  }

  /// [values] applied to every row of [table] matching [key] that exists.
  Future<void> patchLocal(
    SyncTable table,
    Map<String, Object?> key,
    Map<String, Object?> values,
  ) async {
    final existing = await readRow(table, key);
    if (existing == null) return;
    await upsertRows(table, [
      {
        ...existing,
        ...values,
        if (table.writable) 'local_pending': true,
      },
    ]);
  }

  /// The outbox has pushed every change to this row.
  Future<void> clearPending(SyncTable table, Map<String, Object?> key) async {
    if (!table.writable) return;
    await db.customUpdate(
      'UPDATE ${table.name} SET local_pending = 0 WHERE ${_where(table)}',
      variables: _variables(table, key),
      updates: {table.info(db)},
      updateKind: UpdateKind.update,
    );
  }

  // --- Pulled pages ----------------------------------------------------------

  /// Applies one pulled page of [table] for [businessId] and moves the
  /// cursor to [cursor], in one transaction (a crash never leaves rows
  /// applied with the cursor behind, or the reverse).
  ///
  /// A row this device changed and has not pushed yet (`local_pending`) is
  /// left alone: the push will bring the server up to date, and a later
  /// pull returns the merged row. Read inside the same transaction as the
  /// write, so a local change made meanwhile is never overwritten.
  /// Tombstones (a `deleted_at`) are removed locally.
  Future<void> applyPage(
    SyncTable table,
    String businessId,
    List<Map<String, dynamic>> rows, {
    required int cursor,
  }) => db.transaction(() async {
    final pending = {
      for (final row in await pendingRows(table, businessId: businessId))
        table.keyText(row),
    };
    final upserts = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (pending.contains(table.keyText(row))) continue;
      if (row['deleted_at'] != null) {
        await deleteRow(table, table.keyOf(row));
      } else {
        upserts.add(row);
      }
    }
    await upsertRows(table, upserts);
    await setCursor(businessId, table, cursor);
  });

  /// Pulled rows of an unscoped table ([SyncTable.businesses],
  /// [SyncTable.profiles]), except those with a local change waiting.
  Future<void> applyRows(
    SyncTable table,
    List<Map<String, dynamic>> rows,
  ) => db.transaction(() async {
    final pending = {
      for (final row in await pendingRows(table)) table.keyText(row),
    };
    await upsertRows(table, [
      for (final row in rows)
        if (!pending.contains(table.keyText(row))) row,
    ]);
  });

  /// Rows of [table] (of [businessId], when given) with a local change not
  /// pushed yet.
  Future<List<Map<String, dynamic>>> pendingRows(
    SyncTable table, {
    String? businessId,
  }) async {
    if (!table.writable) return const [];
    final info = table.info(db);
    final scoped = businessId != null && table.scoped;
    final result = await db
        .customSelect(
          'SELECT * FROM ${table.name} WHERE local_pending = 1'
          '${scoped ? ' AND business_id = ?' : ''}',
          variables: [if (scoped) Variable.withString(businessId)],
          readsFrom: {info},
        )
        .get();
    return [for (final row in result) rowOf(await info.map(row.data))];
  }

  // --- Cursors ---------------------------------------------------------------

  Future<int> cursor(String businessId, SyncTable table) async {
    final row =
        await (db.select(db.syncCursors)..where(
              (c) =>
                  c.businessId.equals(businessId) &
                  c.tableKey.equals(table.name),
            ))
            .getSingleOrNull();
    return row?.seq ?? 0;
  }

  Future<void> setCursor(String businessId, SyncTable table, int seq) => db
      .into(db.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          businessId: businessId,
          tableKey: table.name,
          seq: Value(seq),
        ),
      );

  // --- Businesses ------------------------------------------------------------

  /// Ids of the businesses stored on this device.
  Future<List<String>> businessIds() async {
    final rows = await db.select(db.businesses).get();
    return [for (final row in rows) row.id];
  }

  /// Removes everything stored for [businessId]: the business, its rows in
  /// every table and its cursors (the user left or was removed).
  Future<void> wipeBusiness(String businessId) => db.transaction(() async {
    for (final table in SyncTable.values.where((t) => t.scoped)) {
      await db.customUpdate(
        'DELETE FROM ${table.name} WHERE business_id = ?',
        variables: [Variable.withString(businessId)],
        updates: {table.info(db)},
        updateKind: UpdateKind.delete,
      );
    }
    await deleteRow(SyncTable.businesses, {'id': businessId});
    await (db.delete(
      db.syncCursors,
    )..where((c) => c.businessId.equals(businessId))).go();
  });

  /// Removes one table's rows and cursor for [businessId] (e.g. the audit
  /// log when the user is no longer an admin).
  Future<void> wipeTable(String businessId, SyncTable table) => db.transaction(
    () async {
      await db.customUpdate(
        'DELETE FROM ${table.name} WHERE business_id = ?',
        variables: [Variable.withString(businessId)],
        updates: {table.info(db)},
        updateKind: UpdateKind.delete,
      );
      await (db.delete(db.syncCursors)..where(
            (c) =>
                c.businessId.equals(businessId) & c.tableKey.equals(table.name),
          ))
          .go();
    },
  );

  // --- Owner -----------------------------------------------------------------

  Future<bool> _claims = Future<bool>.value(false);

  /// Makes this store [uid]'s: data of anyone else signed in before is
  /// wiped first. Returns whether it was wiped. Serialised, so the sign-in
  /// flow and the sync engine claiming at once wipe at most once.
  Future<bool> claimFor(String uid) =>
      _claims = _claims.then((_) => _claim(uid), onError: (_) => _claim(uid));

  Future<bool> _claim(String uid) async {
    final owner = await _meta(_ownerKey);
    if (owner == uid) return false;
    await wipeAll();
    await (db.delete(
      db.localMeta,
    )..where((m) => m.key.equals(_pulledKey))).go();
    await db
        .into(db.localMeta)
        .insertOnConflictUpdate(
          LocalMetaCompanion.insert(key: _ownerKey, value: uid),
        );
    return owner != null;
  }

  /// Signing out: nothing of this user stays on the device, and the next
  /// sign-in (whoever it is) starts from a fresh pull.
  Future<void> release() => _claims = _claims.then(
    (_) => _release(),
    onError: (_) => _release(),
  );

  Future<bool> _release() async {
    await wipeAll();
    await (db.delete(db.localMeta)..where(
          (m) => m.key.equals(_ownerKey) | m.key.equals(_pulledKey),
        ))
        .go();
    return true;
  }

  /// Empties every synced table and cursor (keeps nothing of anyone).
  Future<void> wipeAll() => db.transaction(() async {
    for (final info in db.syncedTables) {
      await db.delete(info).go();
    }
    await db.delete(db.syncCursors).go();
  });

  /// Records that a full pull for the owner has completed.
  Future<void> markPulled() => db
      .into(db.localMeta)
      .insertOnConflictUpdate(
        LocalMetaCompanion.insert(
          key: _pulledKey,
          value: DateTime.now().toUtc().toIso8601String(),
        ),
      );

  /// Whether the store has been filled from the server at least once since
  /// it was claimed: until then "not found locally" means "not known yet",
  /// not "gone". The current value first, then each change.
  Stream<bool> watchPulled() =>
      (db.select(db.localMeta)..where((m) => m.key.equals(_pulledKey)))
          .watchSingleOrNull()
          .map((row) => row != null)
          .distinct();

  Future<bool> hasPulled() async => await _meta(_pulledKey) != null;

  Future<String?> _meta(String key) async {
    final row = await (db.select(
      db.localMeta,
    )..where((m) => m.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  // --- Helpers ---------------------------------------------------------------

  static String _where(SyncTable table) =>
      table.keys.map((key) => '$key = ?').join(' AND ');

  static List<Variable<Object>> _variables(
    SyncTable table,
    Map<String, Object?> key,
  ) => [
    for (final column in table.keys)
      switch (key[column]) {
        final int value => Variable<int>(value),
        final Object value => Variable<String>('$value'),
        null => throw ArgumentError('Missing key column $column'),
      },
  ];
}
