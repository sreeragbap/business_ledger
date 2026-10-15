import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CustomFieldRepository)
class CustomFieldService implements CustomFieldRepository {
  CustomFieldService(this._refs, this._writer, this._db);

  final FirestoreRefs _refs;
  final LocalFirstWriter _writer;
  final FirebaseFirestore _db;

  @override
  Stream<AppResult<List<CustomField>>> watchFields(String businessId) =>
      FirestoreStreams.list(
        _refs.fields(businessId).orderBy('sortOrder'),
        CustomField.fromFirestore,
      );

  @override
  Future<AppResult<String>> create(String businessId, CustomField field) async {
    final ref = _refs.fields(businessId).doc();
    final result = await _writer.commit(
      () => ref.set({
        ...field.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    return result.map((_) => ref.id);
  }

  @override
  Future<AppResult<void>> update(String businessId, CustomField field) =>
      _writer.commit(
        () => _refs.field(businessId, field.id).update({
          ...field.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  @override
  Future<AppResult<void>> reorder(String businessId, Map<String, int> orders) {
    if (orders.isEmpty) return Future.value(const Success(null));
    return _writer.commit(() {
      final batch = _db.batch();
      for (final entry in orders.entries) {
        batch.update(_refs.field(businessId, entry.key), {
          'sortOrder': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return batch.commit();
    });
  }

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
    int? sortOrder,
  }) => _writer.commit(
    () => _refs.field(businessId, id).update({
      'archived': archived,
      'sortOrder': ?sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );
}
