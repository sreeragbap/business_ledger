import 'dart:async';

import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/repository/category_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CategoryRepository)
class CategoryService implements CategoryRepository {
  CategoryService(this._store, this._writer, this._rpc, this._engine);

  final LocalStore _store;
  final LocalWriter _writer;
  final RpcClient _rpc;
  final SyncEngine _engine;

  AppDatabase get _db => _store.db;

  @override
  Stream<AppResult<List<Category>>> watchCategories(String businessId) =>
      LocalStreams.watch(
        (_db.select(_db.categories)
              ..where(
                (c) => c.businessId.equals(businessId) & c.deletedAt.isNull(),
              )
              ..orderBy([
                (c) => OrderingTerm.asc(c.sortOrder),
                (c) => OrderingTerm.asc(c.name),
              ]))
            .watch(),
        (rows) => List<Category>.unmodifiable([
          for (final row in rows) Category.fromRow(rowOf(row)),
        ]),
      );

  @override
  Future<AppResult<Category?>> getCategory(String businessId, String id) =>
      AppResult.guard(() async {
        final row = await _store.readRow(SyncTable.categories, {'id': id});
        if (row == null ||
            row['business_id'] != businessId ||
            row['deleted_at'] != null) {
          return null;
        }
        return Category.fromRow(row);
      });

  @override
  Future<AppResult<String>> create(String businessId, Category category) async {
    final id = RequestIds.rowId();
    final result = await _writer.upsert(
      SyncTable.categories,
      [category.copyWith(id: id).toRow(businessId)],
      businessId: businessId,
      label: 'New category · ${category.name.trim()}',
    );
    return result.map((_) => id);
  }

  @override
  Future<AppResult<void>> update(String businessId, Category category) =>
      _writer.update(
        SyncTable.categories,
        [
          RowUpdate({'id': category.id}, _editable(category)),
        ],
        businessId: businessId,
        label: 'Category · ${category.name.trim()}',
      );

  /// What a client may change: everything but the key.
  static Map<String, Object?> _editable(Category category) =>
      Map.of(category.toRow(''))
        ..remove('id')
        ..remove('business_id');

  @override
  Future<AppResult<void>> reorder(String businessId, Map<String, int> orders) {
    if (orders.isEmpty) return Future.value(const Success(null));
    return _writer.update(
      SyncTable.categories,
      [
        for (final entry in orders.entries)
          RowUpdate({'id': entry.key}, {'sort_order': entry.value}),
      ],
      businessId: businessId,
      label: 'Reorder categories',
    );
  }

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
    int? sortOrder,
  }) => _writer.update(
    SyncTable.categories,
    [
      RowUpdate({'id': id}, {'archived': archived, 'sort_order': ?sortOrder}),
    ],
    businessId: businessId,
    label: archived ? 'Archive category' : 'Unarchive category',
  );

  @override
  Future<AppResult<void>> delete(String businessId, String id) async {
    final result = await _rpc.call('deleteCategory', {
      'businessId': businessId,
      'categoryId': id,
    });
    if (result.isSuccess) {
      try {
        await _engine.refresh().timeout(const Duration(seconds: 8));
      } on TimeoutException {
        // The tombstone arrives with the pull.
      }
    }
    return result.map((_) {});
  }
}
