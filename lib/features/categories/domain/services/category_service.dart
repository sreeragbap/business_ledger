import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/repository/category_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CategoryRepository)
class CategoryService implements CategoryRepository {
  CategoryService(this._refs, this._callable, this._writer, this._db);

  final FirestoreRefs _refs;
  final CallableClient _callable;
  final LocalFirstWriter _writer;
  final FirebaseFirestore _db;

  @override
  Stream<AppResult<List<Category>>> watchCategories(String businessId) =>
      FirestoreStreams.list(
        _refs.categories(businessId).orderBy('sortOrder'),
        Category.fromFirestore,
      );

  @override
  Future<AppResult<Category?>> getCategory(String businessId, String id) =>
      AppResult.guard(() async {
        final doc = await _refs.category(businessId, id).get();
        return doc.exists ? Category.fromFirestore(doc) : null;
      });

  @override
  Future<AppResult<String>> create(String businessId, Category category) async {
    final ref = _refs.categories(businessId).doc();
    final result = await _writer.commit(
      () => ref.set({
        ...category.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    return result.map((_) => ref.id);
  }

  @override
  Future<AppResult<void>> update(String businessId, Category category) =>
      _writer.commit(
        () => _refs.category(businessId, category.id).update({
          ...category.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  @override
  Future<AppResult<void>> reorder(String businessId, Map<String, int> orders) {
    if (orders.isEmpty) return Future.value(const Success(null));
    return _writer.commit(() {
      final batch = _db.batch();
      for (final entry in orders.entries) {
        batch.update(_refs.category(businessId, entry.key), {
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
    () => _refs.category(businessId, id).update({
      'archived': archived,
      'sortOrder': ?sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<AppResult<void>> delete(String businessId, String id) async {
    final result = await _callable.call('deleteCategory', {
      'businessId': businessId,
      'categoryId': id,
    });
    return result.map((_) {});
  }
}
