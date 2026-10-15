import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/domain/repository/project_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'projects_state.dart';

/// Projects: a live list filtered on the device, plus create/edit/archive.
@injectable
class ProjectsCubit extends Cubit<ProjectsState> {
  ProjectsCubit(this._repository) : super(const ProjectsState());

  final ProjectRepository _repository;
  StreamSubscription<AppResult<List<Project>>>? _subscription;
  String? _businessId;

  Future<void> watch(String businessId) async {
    _businessId = businessId;
    await _subscription?.cancel();
    emit(state.copyWith(loadStatus: const Status.loading()));
    _subscription = _repository
        .watchProjects(businessId)
        .listen(
          (result) => emit(
            result.when(
              success: (projects) => state.copyWith(
                projects: projects,
                loadStatus: const Status.success(),
              ),
              failure: (error) =>
                  state.copyWith(loadStatus: Status.fromException(error)),
            ),
          ),
        );
  }

  void search(String query) => emit(state.copyWith(query: query));

  void toggleArchived() =>
      emit(state.copyWith(showArchived: !state.showArchived));

  static Map<String, List<String>> validate(Project project) {
    final name = project.name.trim();
    return {
      if (name.isEmpty)
        'name': ['Enter a name.']
      else if (name.length > Project.maxNameLength)
        'name': ['Keep the name under ${Project.maxNameLength} characters.'],
      if (project.code.trim().length > Project.maxCodeLength)
        'code': ['Keep the code under ${Project.maxCodeLength} characters.'],
    };
  }

  Future<void> save(Project project) async {
    final businessId = _businessId;
    if (businessId == null) return;
    final errors = validate(project);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          actionStatus: Status.failure(
            errors.values.first.first,
            errors: errors,
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(actionStatus: const Status.loading()));
    if (project.id.isEmpty) {
      final result = await _repository.create(businessId, project);
      emit(
        result.when(
          success: (id) => state.copyWith(
            savedId: id,
            actionStatus: Status.success(message: '${project.name} added.'),
          ),
          failure: (error) =>
              state.copyWith(actionStatus: Status.fromException(error)),
        ),
      );
      return;
    }
    final result = await _repository.update(businessId, project);
    emit(
      state.copyWith(
        savedId: project.id,
        actionStatus: result.when(
          success: (_) => const Status.success(message: 'Saved.'),
          failure: Status.fromException,
        ),
      ),
    );
  }

  Future<void> setArchived(Project project, {required bool archived}) async {
    final businessId = _businessId;
    if (businessId == null) return;
    emit(state.copyWith(actionStatus: const Status.loading()));
    final result = await _repository.setArchived(
      businessId,
      project.id,
      archived: archived,
    );
    emit(
      state.copyWith(
        actionStatus: result.when(
          success: (_) => Status.success(
            message: archived
                ? '${project.name} archived.'
                : '${project.name} restored.',
          ),
          failure: Status.fromException,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
