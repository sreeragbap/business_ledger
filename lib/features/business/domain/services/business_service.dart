import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/firestore_read.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/create_business_request.dart';
import 'package:business_ledger/features/business/domain/repository/business_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: BusinessRepository)
class BusinessService implements BusinessRepository {
  BusinessService(this._refs, this._callable, this._writer, this._prefs);

  final FirestoreRefs _refs;
  final CallableClient _callable;
  final LocalFirstWriter _writer;
  final SharedPreferences _prefs;

  static String _prefsKey(String uid) => 'business.last.$uid';

  /// A cold, offline start must not wait on the profile read forever.
  static const Duration _profileReadLimit = Duration(seconds: 5);

  @override
  Stream<AppResult<List<Business>>> watchMyBusinesses(String uid) =>
      // Sorted here rather than with orderBy: array-contains plus orderBy on
      // another field needs a composite index, and a user belongs to a
      // handful of businesses.
      FirestoreStreams.list(
        _refs.businesses.where('memberUids', arrayContains: uid),
        Business.fromFirestore,
      ).map(
        (result) => result.map(
          (businesses) => List<Business>.unmodifiable(
            List<Business>.of(businesses)..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ),
          ),
        ),
      );

  @override
  Stream<AppResult<Business?>> watchBusiness(String businessId) =>
      FirestoreStreams.doc(_refs.business(businessId), Business.fromFirestore);

  @override
  Future<AppResult<String>> createBusiness(
    CreateBusinessRequest request,
  ) async {
    final result = await _callable.call(
      'createBusiness',
      request.toPayload(),
    );
    return result.map((data) => data.readString('businessId'));
  }

  @override
  Future<AppResult<void>> updateDetails(
    String businessId, {
    required String name,
    required String description,
    required String timezone,
    required BusinessSettings settings,
  }) => _writer.commit(
    () => _refs.business(businessId).update({
      ...Business.detailsUpdate(
        name: name,
        description: description,
        timezone: timezone,
        settings: settings,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<AppResult<void>> setArchived(
    String businessId, {
    required bool archived,
  }) => _writer.commit(
    () => _refs.business(businessId).update({
      'archived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<String?> lastBusinessId(String uid) async {
    final cached = _prefs.getString(_prefsKey(uid));
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final snapshot = await _refs.user(uid).get().timeout(_profileReadLimit);
      final id = (snapshot.data() ?? const {}).readOptionalString(
        'lastBusinessId',
      );
      if (id != null) await _prefs.setString(_prefsKey(uid), id);
      return id;
    } catch (_) {
      // Offline with nothing cached, or the profile is unreadable: the
      // picker is the right answer either way.
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
    // Best effort, queued offline; a failure only costs another device the
    // shortcut.
    await _writer.commit(
      () => _refs.user(uid).set({
        'lastBusinessId': businessId ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }
}
