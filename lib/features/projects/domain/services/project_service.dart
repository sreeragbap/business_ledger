import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/domain/repository/project_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ProjectRepository)
class ProjectService implements ProjectRepository {
  ProjectService(this._store, this._writer);

  final LocalStore _store;
  final LocalWriter _writer;

  AppDatabase get _db => _store.db;

  @override
  Stream<AppResult<List<Project>>> watchProjects(String businessId) =>
      LocalStreams.watch(
        (_db.select(_db.projects)
              ..where((row) => row.businessId.equals(businessId))
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .watch(),
        (rows) => List<Project>.unmodifiable([
          for (final row in rows) Project.fromRow(rowOf(row)),
        ]),
      );

  @override
  Future<AppResult<Project?>> getProject(String businessId, String id) =>
      AppResult.guard(() async {
        final row = await _store.readRow(SyncTable.projects, {'id': id});
        if (row == null || row['business_id'] != businessId) return null;
        return Project.fromRow(row);
      });

  @override
  Future<AppResult<String>> create(String businessId, Project project) async {
    final id = RequestIds.rowId();
    final result = await _writer.upsert(
      SyncTable.projects,
      [project.copyWith(id: id).toRow(businessId)],
      businessId: businessId,
      label: 'New project · ${project.name.trim()}',
    );
    return result.map((_) => id);
  }

  @override
  Future<AppResult<void>> update(String businessId, Project project) =>
      _writer.update(
        SyncTable.projects,
        [
          RowUpdate(
            {'id': project.id},
            Map.of(project.toRow(businessId))
              ..remove('id')
              ..remove('business_id'),
          ),
        ],
        businessId: businessId,
        label: 'Project · ${project.name.trim()}',
      );

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  }) => _writer.update(
    SyncTable.projects,
    [
      RowUpdate({'id': id}, {'archived': archived}),
    ],
    businessId: businessId,
    label: archived ? 'Archive project' : 'Unarchive project',
  );
}
