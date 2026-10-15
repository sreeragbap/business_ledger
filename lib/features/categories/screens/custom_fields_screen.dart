import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_async_view.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/logic/custom_fields_cubit/custom_fields_cubit.dart';
import 'package:business_ledger/features/categories/widgets/custom_field_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Business-defined inputs that categories add to the transaction form.
/// Reorderable; archived rather than deleted so past values keep a label.
@RoutePage()
class CustomFieldsScreen extends StatelessWidget implements AutoRouteWrapper {
  const CustomFieldsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final businessId = context.read<BusinessScopeCubit>().state.businessId;
    return BlocProvider<CustomFieldsCubit>(
      create: (_) {
        final cubit = getIt<CustomFieldsCubit>();
        if (businessId != null) unawaited(cubit.watch(businessId));
        return cubit;
      },
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<BusinessScopeCubit, Role>(
      (cubit) => cubit.state.role,
    );
    final canEdit = role.canEditConfig;
    return BlocListener<CustomFieldsCubit, CustomFieldsState>(
      listenWhen: (p, c) =>
          p.actionStatus != c.actionStatus && !c.actionStatus.isLoading,
      listener: (context, state) {
        final status = state.actionStatus;
        if (status.isFailure) {
          showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
        } else if (status.isSuccess && status.message.isNotEmpty) {
          showAppSnackBar(
            context,
            status.message,
            kind: AppSnackBarKind.success,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Custom fields')),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: () => unawaited(_edit(context, null)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New field'),
              )
            : null,
        body: BlocBuilder<CustomFieldsCubit, CustomFieldsState>(
          builder: (context, state) => AppAsyncView<List<CustomField>>(
            status: state.loadStatus,
            data: state.fields,
            isEmpty: (items) => items.isEmpty,
            loading: const AppListSkeleton(rows: 4),
            empty: AppEmptyState(
              icon: Icons.dynamic_form_outlined,
              title: 'No custom fields',
              message:
                  'Add inputs your business needs on entries, like a site, '
                  'a vehicle number or hours, then attach them to '
                  'categories.',
              action: canEdit
                  ? AppButton(
                      label: 'Add a field',
                      icon: Icons.add_rounded,
                      expand: false,
                      onPressed: () => unawaited(_edit(context, null)),
                    )
                  : null,
            ),
            builder: (context, _) => ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal.w,
                AppSpacing.sm.h,
                AppSpacing.screenHorizontal.w,
                96.h,
              ),
              children: [
                if (state.active.isNotEmpty) ...[
                  const AppSectionLabel('Active'),
                  if (canEdit)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: state.active.length,
                      onReorderItem: (oldIndex, newIndex) => unawaited(
                        context.read<CustomFieldsCubit>().reorder(
                          oldIndex,
                          newIndex,
                        ),
                      ),
                      proxyDecorator: (child, _, _) =>
                          Material(color: AppColors.transparent, child: child),
                      itemBuilder: (context, index) {
                        final field = state.active[index];
                        return Padding(
                          key: ValueKey(field.id),
                          padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                          child: _FieldTile(
                            field: field,
                            canEdit: true,
                            dragIndex: index,
                          ),
                        );
                      },
                    )
                  else
                    for (final field in state.active)
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                        child: _FieldTile(field: field, canEdit: false),
                      ),
                  SizedBox(height: AppSpacing.xl.h),
                ],
                if (state.archived.isNotEmpty)
                  AppCollapsibleSection(
                    title: 'Archived',
                    count: state.archived.length,
                    child: Column(
                      children: [
                        for (final field in state.archived)
                          Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                            child: _FieldTile(field: field, canEdit: canEdit),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _edit(BuildContext context, CustomField? field) async {
  final cubit = context.read<CustomFieldsCubit>();
  final result = await showCustomFieldForm(context, field: field);
  if (result != null) await cubit.save(result);
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.field,
    required this.canEdit,
    this.dragIndex,
  });

  final CustomField field;
  final bool canEdit;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dragIndex = this.dragIndex;
    final details = [
      field.type.label,
      if (field.type.hasOptions) '${field.options.length} choices',
      if (field.required) 'Required',
    ].join(' · ');
    return AppCard(
      onTap: canEdit ? () => unawaited(_edit(context, field)) : null,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.sm.h,
        AppSpacing.xs.w,
        AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          Icon(
            field.type.icon,
            size: 22.r,
            color: field.archived ? AppColors.textTertiary : null,
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: textTheme.titleSmall?.copyWith(
                    color: field.archived ? AppColors.textSecondary : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(details, style: textTheme.bodySmall),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<bool>(
              tooltip: 'Field actions',
              onSelected: (archive) {
                final cubit = context.read<CustomFieldsCubit>();
                unawaited(
                  archive ? cubit.archive(field) : cubit.unarchive(field),
                );
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: !field.archived,
                  child: Text(field.archived ? 'Restore' : 'Archive'),
                ),
              ],
            ),
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm.r),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 22.r,
                  semanticLabel: 'Drag to reorder',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
