import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/supabase/remote_tables.dart';
import 'package:injectable/injectable.dart';

/// The signed-in user's `profiles` row (`supabase/README.md`): display name
/// and photo from the sign-in provider, and the business they last worked
/// in. The row must exist before anyone can add them to a business
/// (`add_member` finds people by its email, which the database takes from
/// the verified token).
///
/// Changes are written to the local row first (`local_pending`) and pushed
/// by [push]: right after sign-in, and by the sync engine before each pull.
/// Not part of the outbox: a profile update is best effort and must never
/// block signing out.
@lazySingleton
class ProfileSync {
  ProfileSync(this._store, this._remote);

  final LocalStore _store;
  final RemoteTables _remote;

  /// Records the provider's name and photo for [uid] (claiming the local
  /// store for them first, so a previous user's data is gone).
  Future<void> saveSignIn({
    required String uid,
    String? displayName,
    String? photoUrl,
  }) async {
    await _store.claimFor(uid);
    await _store.writeLocal(SyncTable.profiles, {
      'id': uid,
      'display_name': (displayName ?? '').trim(),
      'photo_url': (photoUrl ?? '').trim(),
    });
  }

  /// Records [businessId] as [uid]'s last business.
  Future<void> saveLastBusiness(String uid, String? businessId) async {
    await _store.writeLocal(SyncTable.profiles, {
      'id': uid,
      'last_business_id': businessId,
    });
  }

  /// Signing out: the device keeps nothing of the user (their outbox is
  /// empty by then: the sign-out guard sees to it).
  Future<void> forgetDevice() => _store.release();

  /// The last business stored on this device for [uid] (pulled from the
  /// server or set here).
  Future<String?> lastBusinessId(String uid) async {
    final row = await _store.readRow(SyncTable.profiles, {'id': uid});
    final id = row?['last_business_id'];
    return id is String && id.isNotEmpty ? id : null;
  }

  /// Upserts [uid]'s row if it has a local change. Never throws.
  ///
  /// Only the columns the client owns are sent; `email` is set by the
  /// database from the token. A cleared last business is not sent (the
  /// column keeps its value: it is only a shortcut, checked against
  /// membership when used).
  Future<AppResult<void>> push(String uid) => AppResult.guard(() async {
    final row = await _store.readRow(SyncTable.profiles, {'id': uid});
    if (row == null || row['local_pending'] != true) return;
    final lastBusiness = row['last_business_id'];
    await _remote.upsert(SyncTable.profiles.name, [
      {
        'id': uid,
        'display_name': row['display_name'] ?? '',
        'photo_url': row['photo_url'] ?? '',
        if (lastBusiness is String && lastBusiness.isNotEmpty)
          'last_business_id': lastBusiness,
      },
    ]);
    // Cleared only if nothing changed while the request was out.
    final after = await _store.readRow(SyncTable.profiles, {'id': uid});
    if (after?['updated_at'] == row['updated_at']) {
      await _store.clearPending(SyncTable.profiles, {'id': uid});
    }
  });
}
