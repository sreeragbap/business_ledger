import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/supabase/remote_tables.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/outbox_executor.dart';
import 'package:business_ledger/core/sync/sync_identity.dart';
import 'package:injectable/injectable.dart';

/// Writes drafts and configuration the local-first way
/// (`docs/ARCHITECTURE.md` §2, Offline behaviour).
///
/// A write goes to the on-device store at once (every screen watching the
/// table sees it, online or not) **and** into the outbox as an `upsert` or
/// `update` entry, which the sync engine pushes through PostgREST in FIFO
/// order with the money actions: a draft's upsert always reaches the server
/// before the confirm queued after it. The caller gets [Success] as soon as
/// both are stored; a refusal that comes later marks the entry failed on
/// the Sync screen (and a snack bar says so).
@lazySingleton
class LocalWriter {
  LocalWriter(
    this._store,
    this._outbox,
    this._identity,
    this._remote,
    this._availability, {
    @ignoreParam DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final LocalStore _store;
  final Outbox _outbox;
  final SyncIdentity _identity;
  final RemoteTables _remote;
  final CloudAvailability _availability;
  final DateTime Function() _now;

  /// Inserts or replaces whole rows (new drafts, new configuration).
  ///
  /// With [awaitServer] (a draft about to be confirmed) the rows are sent
  /// now and stored locally only once the server has them; offline that
  /// fails with `AppErrorKind.offline` and the caller falls back to a
  /// queued write. If anything of this user still waits in the outbox, the
  /// write is queued behind it instead (order matters).
  Future<AppResult<void>> upsert(
    SyncTable table,
    List<Map<String, Object?>> rows, {
    required String businessId,
    required String label,
    String? transactionId,
    bool awaitServer = false,
  }) => _write(
    kind: OutboxKind.upsert,
    table: table,
    payload: {'table': table.name, 'rows': rows},
    businessId: businessId,
    label: label,
    transactionId: transactionId,
    awaitServer: awaitServer,
    applyLocal: () async {
      for (final row in rows) {
        await _store.writeLocal(table, row);
      }
    },
    send: () => _remote.upsert(table.name, [
      for (final row in rows) Map<String, dynamic>.of(row),
    ]),
  );

  /// Sets columns on existing rows (edits, reorders, archives, soft
  /// deletes). [awaitServer] as for [upsert].
  Future<AppResult<void>> update(
    SyncTable table,
    List<RowUpdate> updates, {
    required String businessId,
    required String label,
    String? transactionId,
    bool awaitServer = false,
  }) => _write(
    kind: OutboxKind.update,
    table: table,
    payload: {
      'table': table.name,
      'updates': [for (final update in updates) update.toJson()],
    },
    businessId: businessId,
    label: label,
    transactionId: transactionId,
    awaitServer: awaitServer,
    applyLocal: () async {
      for (final update in updates) {
        await _store.patchLocal(table, update.match, update.values);
      }
    },
    send: () async {
      for (final update in updates) {
        final changed = await _remote.update(
          table.name,
          update.match,
          update.values,
        );
        if (changed == 0) throw SupabaseOutboxExecutor.updateRefused;
      }
    },
  );

  Future<AppResult<void>> _write({
    required OutboxKind kind,
    required SyncTable table,
    required Map<String, Object?> payload,
    required String businessId,
    required String label,
    required String? transactionId,
    required bool awaitServer,
    required Future<void> Function() applyLocal,
    required Future<void> Function() send,
  }) async {
    final uid = _identity.uid;
    if (uid == null) return const Failure(CloudAvailability.signedOut);

    if (awaitServer && !await _hasQueued(uid)) {
      if (!await _availability.refresh()) {
        return Failure(_availability.unavailableError);
      }
      try {
        await send();
      } catch (error) {
        return Failure(AppException.from(error));
      }
      return AppResult.guard(() async {
        await applyLocal();
        for (final key in _keysOf(table, payload)) {
          await _store.clearPending(table, key);
        }
      });
    }

    return AppResult.guard(() async {
      await applyLocal();
      await _outbox.add(
        OutboxEntry(
          id: RequestIds.next(),
          uid: uid,
          businessId: businessId,
          kind: kind,
          payload: payload,
          transactionId: transactionId,
          label: label,
          createdAt: _now(),
        ),
      );
    });
  }

  Future<bool> _hasQueued(String uid) async {
    await _outbox.load();
    return _outbox.entries.any(
      (entry) => entry.uid == uid && !entry.isFailed,
    );
  }

  static List<Map<String, Object?>> _keysOf(
    SyncTable table,
    Map<String, Object?> payload,
  ) => OutboxEntry(
    id: 'keys',
    uid: '',
    businessId: '',
    kind: payload.containsKey('rows') ? OutboxKind.upsert : OutboxKind.update,
    payload: payload,
    label: '',
    createdAt: DateTime.utc(2000),
  ).rowKeys;
}
