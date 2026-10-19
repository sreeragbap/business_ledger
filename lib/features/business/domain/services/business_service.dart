import 'dart:async';

import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/profile_sync.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/create_business_request.dart';
import 'package:business_ledger/features/business/domain/repository/business_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [BusinessRepository] over the on-device store (reads), the outbox
/// (settings) and the `create_business` RPC.
@LazySingleton(as: BusinessRepository)
class BusinessService implements BusinessRepository {
  BusinessService(
    this._store,
    this._rpc,
    this._writer,
    this._prefs,
    this._profiles,
    this._engine,
  );

  final LocalStore _store;
  final RpcClient _rpc;
  final LocalWriter _writer;
  final SharedPreferences _prefs;
  final ProfileSync _profiles;
  final SyncEngine _engine;

  AppDatabase get _db => _store.db;

  static String _prefsKey(String uid) => 'business.last.$uid';

  /// A first start on this device must not wait on the server forever.
  static const Duration _pullWait = Duration(seconds: 5);

  @override
  Stream<AppResult<List<Business>>> watchMyBusinesses(String uid) {
    final query = _db.select(_db.businesses).join([
      innerJoin(
        _db.members,
        _db.members.businessId.equalsExp(_db.businesses.id) &
            _db.members.userId.equals(uid) &
            _db.members.deletedAt.isNull(),
      ),
    ]);
    return LocalStreams.watch(
      query.watch(),
      (rows) => List<Business>.unmodifiable(
        <Business>[
          for (final row in rows)
            Business.fromRow(rowOf(row.readTable(_db.businesses))),
        ]..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        ),
      ),
    );
  }

  @override
  Stream<AppResult<Business?>> watchBusiness(String businessId) =>
      LocalStreams.single(
        (_db.select(
          _db.businesses,
        )..where((b) => b.id.equals(businessId))).watchSingleOrNull(),
        _store.watchPulled(),
        (row) => Business.fromRow(rowOf(row)),
      );

  @override
  Future<AppResult<String>> createBusiness(
    CreateBusinessRequest request,
  ) async {
    final result = await _rpc.call('createBusiness', request.toPayload());
    if (result case Success(:final data)) {
      // The new business, its membership and template rows come down
      // before the caller opens it.
      try {
        await _engine.refresh().timeout(const Duration(seconds: 15));
      } on TimeoutException {
        // Opened anyway; the scope waits for the rows to arrive.
      }
      return Success(data.readString('businessId'));
    }
    return result.map((data) => data.readString('businessId'));
  }

  @override
  Future<AppResult<void>> updateDetails(
    String businessId, {
    required String name,
    required String description,
    required String timezone,
    required BusinessSettings settings,
  }) async {
    final stored = await _store.readRow(SyncTable.businesses, {
      'id': businessId,
    });
    return _writer.update(
      SyncTable.businesses,
      [
        RowUpdate(
          {'id': businessId},
          Business.detailsUpdate(
            name: name,
            description: description,
            timezone: timezone,
            settings: settings,
            storedSettings: stored?.readMap('settings') ?? const {},
          ),
        ),
      ],
      businessId: businessId,
      label: 'Business details · ${name.trim()}',
    );
  }

  @override
  Future<AppResult<void>> setArchived(
    String businessId, {
    required bool archived,
  }) => _writer.update(
    SyncTable.businesses,
    [
      RowUpdate({'id': businessId}, {'archived': archived}),
    ],
    businessId: businessId,
    label: archived ? 'Archive business' : 'Unarchive business',
  );

  @override
  Future<String?> lastBusinessId(String uid) async {
    final cached = _prefs.getString(_prefsKey(uid));
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      var id = await _profiles.lastBusinessId(uid);
      if (id == null && !await _store.hasPulled()) {
        // A first start on this device: the profile row comes with the
        // first pull. Offline, the picker is the right answer.
        await _engine.refresh().timeout(_pullWait);
        id = await _profiles.lastBusinessId(uid);
      }
      if (id != null) await _prefs.setString(_prefsKey(uid), id);
      return id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> rememberBusiness(String uid, String? businessId) async {
    if (businessId == null) {
      await _prefs.remove(_prefsKey(uid));
    } else {
      await _prefs.setString(_prefsKey(uid), businessId);
    }
    // Best effort: pushed with the next sync; a failure only costs another
    // device the shortcut.
    try {
      await _profiles.saveLastBusiness(uid, businessId);
    } catch (_) {
      // The local store is unavailable; the preference above is enough.
    }
  }
}
