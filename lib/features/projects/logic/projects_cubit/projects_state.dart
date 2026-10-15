part of 'projects_cubit.dart';

class ProjectsState extends Equatable {
  const ProjectsState({
    this.projects,
    this.loadStatus = const Status.initial(),
    this.query = '',
    this.showArchived = false,
    this.actionStatus = const Status.initial(),
    this.savedId,
  });

  /// Every project, archived included, by name. `null` until loaded.
  final List<Project>? projects;
  final Status loadStatus;
  final String query;
  final bool showArchived;
  final Status actionStatus;
  final String? savedId;

  List<Project>? get visible => projects
      ?.where(
        (project) =>
            project.archived == showArchived && project.matchesQuery(query),
      )
      .toList(growable: false);

  int get archivedCount =>
      projects?.where((project) => project.archived).length ?? 0;

  ProjectsState copyWith({
    List<Project>? projects,
    Status? loadStatus,
    String? query,
    bool? showArchived,
    Status? actionStatus,
    String? savedId,
  }) => ProjectsState(
    projects: projects ?? this.projects,
    loadStatus: loadStatus ?? this.loadStatus,
    query: query ?? this.query,
    showArchived: showArchived ?? this.showArchived,
    actionStatus: actionStatus ?? this.actionStatus,
    savedId: savedId ?? this.savedId,
  );

  @override
  List<Object?> get props => [
    projects,
    loadStatus,
    query,
    showArchived,
    actionStatus,
    savedId,
  ];
}
