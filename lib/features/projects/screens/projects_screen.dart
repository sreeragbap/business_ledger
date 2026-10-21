import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_async_view.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/logic/projects_cubit/projects_cubit.dart';
import 'package:business_ledger/features/projects/widgets/project_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Jobs, sites and engagements that transactions can be tagged with.
@RoutePage()
class ProjectsScreen extends StatelessWidget implements AutoRouteWrapper {
  const ProjectsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final businessId = context.read<BusinessScopeCubit>().state.businessId;
    return BlocProvider<ProjectsCubit>(
      create: (_) {
        final cubit = getIt<ProjectsCubit>();
        if (businessId != null) unawaited(cubit.watch(businessId));
        return cubit;
      },
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<BusinessScopeCubit>().state;
    final canEdit = scope.role.canEditConfig;
    final projectsOn =
        scope.business?.isEnabled(StandardField.project) ?? false;
    return BlocListener<ProjectsCubit, ProjectsState>(
      listenWhen: (p, c) =>
          p.actionStatus != c.actionStatus && !c.actionStatus.isLoading,
      listener: (context, state) {
        final status = state.actionStatus;
        if (status.isFailure) {
          showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
        } else if (status.isSuccess) {
          showAppSnackBar(
            context,
            status.message,
            kind: AppSnackBarKind.success,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Projects'),
          actions: [
            BlocBuilder<ProjectsCubit, ProjectsState>(
              buildWhen: (p, c) =>
                  p.showArchived != c.showArchived ||
                  p.archivedCount != c.archivedCount,
              builder: (context, state) =>
                  state.archivedCount == 0 && !state.showArchived
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: state.showArchived
                          ? 'Show active'
                          : 'Show archived',
                      icon: Icon(
                        state.showArchived
                            ? Icons.inventory_2_rounded
                            : Icons.inventory_2_outlined,
                      ),
                      onPressed: context.read<ProjectsCubit>().toggleArchived,
                    ),
            ),
          ],
        ),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: () => unawaited(_edit(context, null)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New project'),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal.w,
                AppSpacing.xs.h,
                AppSpacing.screenHorizontal.w,
                AppSpacing.sm.h,
              ),
              child: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    child: projectsOn
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                            child: AppCard(
                              child: Text(
                                'The project field is switched off for this '
                                'business. Turn it on in Business details › '
                                'Transaction form to tag entries.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                  ),
                  AppTextField(
                    hint: 'Search name or code',
                    prefixIcon: Icons.search_rounded,
                    textInputAction: TextInputAction.search,
                    onChanged: context.read<ProjectsCubit>().search,
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProjectsCubit, ProjectsState>(
                builder: (context, state) => AppAsyncView<List<Project>>(
                  status: state.loadStatus,
                  data: state.visible,
                  isEmpty: (items) => items.isEmpty,
                  loading: const AppListSkeleton(),
                  empty: state.query.trim().isNotEmpty
                      ? const AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                        )
                      : AppEmptyState(
                          icon: Icons.work_outline_rounded,
                          title: state.showArchived
                              ? 'Nothing archived'
                              : 'No projects yet',
                          message: state.showArchived
                              ? null
                              : 'Track income and spending per job, site '
                                    'or client engagement.',
                          action: canEdit && !state.showArchived
                              ? AppButton(
                                  label: 'Add a project',
                                  icon: Icons.add_rounded,
                                  expand: false,
                                  onPressed: () =>
                                      unawaited(_edit(context, null)),
                                )
                              : null,
                        ),
                  builder: (context, projects) => ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal.w,
                      AppSpacing.sm.h,
                      AppSpacing.screenHorizontal.w,
                      96.h,
                    ),
                    itemCount: projects.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppSpacing.sm.h),
                    itemBuilder: (context, index) => _ProjectTile(
                      project: projects[index],
                      canEdit: canEdit,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _edit(BuildContext context, Project? project) async {
  final cubit = context.read<ProjectsCubit>();
  final result = await showProjectForm(context, project: project);
  if (result != null) await cubit.save(result);
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.canEdit});

  final Project project;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: canEdit ? () => unawaited(_edit(context, project)) : null,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.md.h,
        AppSpacing.xs.w,
        AppSpacing.md.h,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: context.colors.surfaceHigh,
            child: Icon(Icons.work_outline_rounded, size: 18.r),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.code.isNotEmpty || project.description.isNotEmpty)
                  Text(
                    [
                      if (project.code.isNotEmpty) project.code,
                      if (project.description.isNotEmpty) project.description,
                    ].join(' · '),
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<bool>(
              tooltip: 'Actions',
              onSelected: (archive) => unawaited(
                context.read<ProjectsCubit>().setArchived(
                  project,
                  archived: archive,
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: !project.archived,
                  child: Text(project.archived ? 'Restore' : 'Archive'),
                ),
              ],
            )
          else
            SizedBox(width: AppSpacing.md.w),
        ],
      ),
    );
  }
}
