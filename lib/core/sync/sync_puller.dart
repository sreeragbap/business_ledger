import 'dart:async';
import 'dart:developer' as developer;

import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/supabase/remote_tables.dart';
import 'package:injectable/injectable.dart';

/// Brings the on-device store up to date with Supabase (`supabase/README.md`,
/// Sync; `docs/ARCHITECTURE.md` §2).
///
/// One pull, for the signed-in user:
///
/// 1. their own `profiles` row;
/// 2. every `businesses` row RLS lets them read (= where they are a
///    member). A business stored locally but no longer returned (they left
///    or were removed) is wiped from the device with all its rows;
/// 3. per business and table, the rows with `seq` above the stored cursor,
///    in pages of [pageSize] ordered by `seq`. Each page is applied and the
///    cursor moved in one local transaction; soft-deleted rows (tombstones)
///    are removed locally. `audit_log` only for admins and owners.
///
/// A row this device changed and has not pushed yet (`local_pending`) is
/// never overwritten: the push brings the server up to date, and a later
/// pull returns the result (with a new `seq`).
///
/// Calls are serialised: a pull asked for while one runs waits for the next
/// run (which starts after it), so its caller always sees fresh data.
@lazySingleton
class SyncPuller {
  SyncPuller(this._remote, this._store);

  final RemoteTables _remote;
  final LocalStore _store;

  static const int pageSize = 500;

  Future<AppResult<void>>? _running;
  Completer<AppResult<void>>? _next;
  String? _nextUid;

  /// Pulls everything [uid] can read. Never throws: a failure (offline, a
  /// refused token) comes back as a [Failure] and the store keeps what it
  /// had.
  Future<AppResult<void>> pull(String uid) {
    if (_running == null) {
      final run = _guarded(uid);
      _running = run;
      unawaited(run.whenComplete(_finished));
      return run;
    }
    _nextUid = uid;
    return (_next ??= Completer<AppResult<void>>()).future;
  }

  void _finished() {
    _running = null;
    final next = _next;
    final uid = _nextUid;
    _next = null;
    _nextUid = null;
    if (next == null || uid == null) return;
    final run = _guarded(uid);
    _running = run;
    unawaited(run.whenComplete(_finished));
    next.complete(run);
  }

  Future<AppResult<void>> _guarded(String uid) async {
    try {
      await _run(uid);
      return const Success(null);
    } catch (error, stack) {
      final failure = AppException.from(error);
      developer.log(
        'Pull failed: $failure',
        name: 'sync',
        error: error,
        stackTrace: failure.kind == AppErrorKind.unknown ? stack : null,
      );
      return Failure(failure);
    }
  }

  Future<void> _run(String uid) async {
    await _pullProfile(uid);

    final businesses = await _remote.select(SyncTable.businesses.name);
    final remoteIds = {
      for (final row in businesses)
        if (row['id'] case final String id) id,
    };
    for (final id in await _store.businessIds()) {
      if (!remoteIds.contains(id)) await _store.wipeBusiness(id);
    }
    await _store.applyRows(SyncTable.businesses, businesses);

    for (final businessId in remoteIds) {
      await _pullBusiness(uid, businessId);
    }
    await _store.markPulled();
  }

  Future<void> _pullProfile(String uid) async {
    final rows = await _remote.select(
      SyncTable.profiles.name,
      equals: {'id': uid},
    );
    await _store.applyRows(SyncTable.profiles, rows);
  }

  Future<void> _pullBusiness(String uid, String businessId) async {
    for (final table in SyncTable.perBusiness) {
      if (table.adminOnly && !await _isAdmin(uid, businessId)) {
        // Demoted (or never admin): nothing of it may stay on the device.
        if (await _store.cursor(businessId, table) > 0) {
          await _store.wipeTable(businessId, table);
        }
        continue;
      }
      try {
        await _pullTable(businessId, table);
      } on Object catch (error) {
        final failure = AppException.from(error);
        // Removed from this business mid-pull: RLS now hides its rows. The
        // next pull drops it; other businesses go on.
        if (failure.kind == AppErrorKind.permissionDenied ||
            failure.kind == AppErrorKind.notFound) {
          continue;
        }
        rethrow;
      }
    }
  }

  Future<void> _pullTable(String businessId, SyncTable table) async {
    while (true) {
      final cursor = await _store.cursor(businessId, table);
      final rows = await _remote.changes(
        table.name,
        businessId: businessId,
        afterSeq: cursor,
        limit: pageSize,
      );
      if (rows.isEmpty) return;
      var last = cursor;
      for (final row in rows) {
        final seq = row['seq'];
        if (seq is int && seq > last) last = seq;
      }
      await _store.applyPage(table, businessId, rows, cursor: last);
      if (rows.length < pageSize) return;
    }
  }

  Future<bool> _isAdmin(String uid, String businessId) async {
    final member = await _store.readRow(SyncTable.members, {
      'business_id': businessId,
      'user_id': uid,
    });
    final role = member?['role'];
    return role == 'admin' || role == 'owner';
  }
}
