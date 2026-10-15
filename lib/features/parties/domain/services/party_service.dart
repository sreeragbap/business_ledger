import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/domain/repository/party_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PartyRepository)
class PartyService implements PartyRepository {
  PartyService(this._refs, this._writer);

  final FirestoreRefs _refs;
  final LocalFirstWriter _writer;

  @override
  Stream<AppResult<List<Party>>> watchParties(String businessId) =>
      FirestoreStreams.list(
        _refs.parties(businessId).orderBy('name'),
        Party.fromFirestore,
      );

  @override
  Future<AppResult<Party?>> getParty(String businessId, String id) =>
      AppResult.guard(() async {
        final doc = await _refs.party(businessId, id).get();
        return doc.exists ? Party.fromFirestore(doc) : null;
      });

  @override
  Future<AppResult<String>> create(String businessId, Party party) async {
    final ref = _refs.parties(businessId).doc();
    final result = await _writer.commit(
      () => ref.set({
        ...party.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    return result.map((_) => ref.id);
  }

  @override
  Future<AppResult<void>> update(String businessId, Party party) =>
      _writer.commit(
        () => _refs.party(businessId, party.id).update({
          ...party.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  }) => _writer.commit(
    () => _refs.party(businessId, id).update({
      'archived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );
}
