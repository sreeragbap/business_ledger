import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/domain/repository/project_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ProjectRepository)
class ProjectService implements ProjectRepository {
  ProjectService(this._refs, this._writer);

  final FirestoreRefs _refs;
  final LocalFirstWriter _writer;

  @override
  Stream<AppResult<List<Project>>> watchProjects(String businessId) =>
      FirestoreStreams.list(
        _refs.projects(businessId).orderBy('name'),
        Project.fromFirestore,
      );

  @override
  Future<AppResult<Project?>> getProject(String businessId, String id) =>
      AppResult.guard(() async {
        final doc = await _refs.project(businessId, id).get();
        return doc.exists ? Project.fromFirestore(doc) : null;
      });

  @override
  Future<AppResult<String>> create(String businessId, Project project) async {
    final ref = _refs.projects(businessId).doc();
    final result = await _writer.commit(
      () => ref.set({
        ...project.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    return result.map((_) => ref.id);
  }

  @override
  Future<AppResult<void>> update(String businessId, Project project) =>
      _writer.commit(
        () => _refs.project(businessId, project.id).update({
          ...project.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  }) => _writer.commit(
    () => _refs.project(businessId, id).update({
      'archived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );
}
