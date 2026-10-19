import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CustomFieldRepository)
class CustomFieldService implements CustomFieldRepository {
  CustomFieldService(this._store, this._writer);

  final LocalStore _store;
  final LocalWriter _writer;

  AppDatabase get _db => _store.db;

  @override
  Stream<AppResult<List<CustomField>>> watchFields(String businessId) =>
      LocalStreams.watch(
        (_db.select(_db.customFields)
              ..where((f) => f.businessId.equals(businessId))
              ..orderBy([
                (f) => OrderingTerm.asc(f.sortOrder),
                (f) => OrderingTerm.asc(f.label),
              ]))
            .watch(),
        (rows) => List<CustomField>.unmodifiable([
          for (final row in rows) CustomField.fromRow(rowOf(row)),
        ]),
      );

  @override
  Future<AppResult<String>> create(String businessId, CustomField field) async {
    final id = RequestIds.rowId();
    final result = await _writer.upsert(
      SyncTable.customFields,
      [field.copyWith(id: id).toRow(businessId)],
      businessId: businessId,
      label: 'New field · ${field.label.trim()}',
    );
    return result.map((_) => id);
  }

  @override
  Future<AppResult<void>> update(String businessId, CustomField field) =>
      _writer.update(
        SyncTable.customFields,
        [
          RowUpdate(
            {'id': field.id},
            Map.of(field.toRow(businessId))
              ..remove('id')
              ..remove('business_id'),
          ),
        ],
        businessId: businessId,
        label: 'Field · ${field.label.trim()}',
      );

  @override
  Future<AppResult<void>> reorder(String businessId, Map<String, int> orders) {
    if (orders.isEmpty) return Future.value(const Success(null));
    return _writer.update(
      SyncTable.customFields,
      [
        for (final entry in orders.entries)
          RowUpdate({'id': entry.key}, {'sort_order': entry.value}),
      ],
      businessId: businessId,
      label: 'Reorder fields',
    );
  }

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
    int? sortOrder,
  }) => _writer.update(
    SyncTable.customFields,
    [
      RowUpdate({'id': id}, {'archived': archived, 'sort_order': ?sortOrder}),
    ],
    businessId: businessId,
    label: archived ? 'Archive field' : 'Unarchive field',
  );
}
