import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';

/// A business's projects. Direct, offline-friendly Firestore writes;
/// archived rather than deleted.
///
/// For the transaction form (only when `StandardField.project` is enabled):
/// [watchProjects], offer the non-archived ones, store `projectId` plus a
/// `projectName` snapshot.
abstract class ProjectRepository {
  const ProjectRepository();

  /// Every project, archived included, ordered by name. Live.
  Stream<AppResult<List<Project>>> watchProjects(String businessId);

  Future<AppResult<Project?>> getProject(String businessId, String id);

  /// Creates [project] (its `id` is ignored) and returns the new id.
  Future<AppResult<String>> create(String businessId, Project project);

  Future<AppResult<void>> update(String businessId, Project project);

  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  });
}
