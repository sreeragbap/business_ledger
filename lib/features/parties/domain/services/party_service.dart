import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/domain/repository/party_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PartyRepository)
class PartyService implements PartyRepository {
  PartyService(this._store, this._writer);

  final LocalStore _store;
  final LocalWriter _writer;

  AppDatabase get _db => _store.db;

  @override
  Stream<AppResult<List<Party>>> watchParties(String businessId) =>
      LocalStreams.watch(
        (_db.select(_db.parties)
              ..where((row) => row.businessId.equals(businessId))
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .watch(),
        (rows) => List<Party>.unmodifiable([
          for (final row in rows) Party.fromRow(rowOf(row)),
        ]),
      );

  @override
  Future<AppResult<Party?>> getParty(String businessId, String id) =>
      AppResult.guard(() async {
        final row = await _store.readRow(SyncTable.parties, {'id': id});
        if (row == null || row['business_id'] != businessId) return null;
        return Party.fromRow(row);
      });

  @override
  Future<AppResult<String>> create(String businessId, Party party) async {
    final id = RequestIds.rowId();
    final result = await _writer.upsert(
      SyncTable.parties,
      [party.copyWith(id: id).toRow(businessId)],
      businessId: businessId,
      label: 'New party · ${party.name.trim()}',
    );
    return result.map((_) => id);
  }

  @override
  Future<AppResult<void>> update(String businessId, Party party) =>
      _writer.update(
        SyncTable.parties,
        [
          RowUpdate(
            {'id': party.id},
            Map.of(party.toRow(businessId))
              ..remove('id')
              ..remove('business_id'),
          ),
        ],
        businessId: businessId,
        label: 'Party · ${party.name.trim()}',
      );

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  }) => _writer.update(
    SyncTable.parties,
    [
      RowUpdate({'id': id}, {'archived': archived}),
    ],
    businessId: businessId,
    label: archived ? 'Archive party' : 'Unarchive party',
  );
}
