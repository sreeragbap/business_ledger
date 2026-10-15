import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_async_view.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/logic/categories_cubit/categories_cubit.dart';
import 'package:business_ledger/features/categories/widgets/category_form_sheet.dart';
import 'package:business_ledger/features/categories/widgets/category_icon_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Categories grouped by kind, each group drag-to-reorder (editors and up).
/// Archived categories sit in a collapsed section and can be restored.
/// Deleting goes through the server, which refuses when transactions use
/// the category and suggests archiving instead.
@RoutePage()
class CategoriesScreen extends StatelessWidget implements AutoRouteWrapper {
  const CategoriesScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final businessId = context.read<BusinessScopeCubit>().state.businessId;
    return BlocProvider<CategoriesCubit>(
      create: (_) {
        final cubit = getIt<CategoriesCubit>();
        if (businessId != null) unawaited(cubit.watch(businessId));
        return cubit;
      },
      child: this,
    );
  }

  Future<void> _onAction(BuildContext context, CategoriesState state) async {
    final status = state.actionStatus;
    if (state.deleteBlockedByUse) {
      final category = state.categories?.firstWhere(
        (item) => item.id == state.targetId,
        orElse: () => const Category(id: '', name: ''),
      );
      if (category == null || category.id.isEmpty || category.archived) {
        showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
        return;
      }
      final cubit = context.read<CategoriesCubit>();
      final archive = await showAppConfirmDialog(
        context: context,
        title: '${category.name} is in use',
        message: status.message,
        confirmLabel: 'Archive instead',
      );
      if (archive) await cubit.archive(category);
      return;
    }
    if (!context.mounted) return;
    if (status.isFailure) {
      showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
    } else if (status.isSuccess && status.message.isNotEmpty) {
      showAppSnackBar(context, status.message, kind: AppSnackBarKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<BusinessScopeCubit, Role>(
      (cubit) => cubit.state.role,
    );
    final canEdit = role.canEditConfig;
    return BlocListener<CategoriesCubit, CategoriesState>(
      listenWhen: (p, c) =>
          p.actionStatus != c.actionStatus && !c.actionStatus.isLoading,
      listener: (context, state) => unawaited(_onAction(context, state)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: () => unawaited(_edit(context, null)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New category'),
              )
            : null,
        body: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) => AppAsyncView<List<Category>>(
            status: state.loadStatus,
            data: state.categories,
            isEmpty: (items) => items.isEmpty,
            loading: const AppListSkeleton(),
            empty: AppEmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message:
                  'Categories sort income and expenses so reports make '
                  'sense: Sales, Rent, Fuel…',
              action: canEdit
                  ? AppButton(
                      label: 'Add a category',
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
                if (canEdit)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
                    child: Text(
                      'Drag the handle to change the order categories are '
                      'offered in.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                for (final kind in CategoryKind.values)
                  if (state.activeOf(kind).isNotEmpty) ...[
                    AppSectionLabel(
                      kind.label,
                      trailing: Text(
                        '${state.activeOf(kind).length}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    _KindSection(
                      kind: kind,
                      categories: state.activeOf(kind),
                      state: state,
                      canEdit: canEdit,
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                  ],
                if (state.archived.isNotEmpty)
                  AppCollapsibleSection(
                    title: 'Archived',
                    count: state.archived.length,
                    child: Column(
                      children: [
                        for (final category in state.archived)
                          Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                            child: _CategoryTile(
                              category: category,
                              state: state,
                              canEdit: canEdit,
                            ),
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

Future<void> _edit(BuildContext context, Category? category) async {
  final cubit = context.read<CategoriesCubit>();
  final result = await showCategoryForm(
    context,
    category: category,
    fields: cubit.state.fields,
  );
  if (result != null) await cubit.save(result);
}

class _KindSection extends StatelessWidget {
  const _KindSection({
    required this.kind,
    required this.categories,
    required this.state,
    required this.canEdit,
  });

  final CategoryKind kind;
  final List<Category> categories;
  final CategoriesState state;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    if (!canEdit) {
      return Column(
        children: [
          for (final category in categories)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
              child: _CategoryTile(
                category: category,
                state: state,
                canEdit: false,
              ),
            ),
        ],
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: categories.length,
      onReorderItem: (oldIndex, newIndex) => unawaited(
        context.read<CategoriesCubit>().reorder(kind, oldIndex, newIndex),
      ),
      proxyDecorator: (child, _, _) =>
          Material(color: AppColors.transparent, child: child),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          key: ValueKey(category.id),
          padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
          child: _CategoryTile(
            category: category,
            state: state,
            canEdit: true,
            dragIndex: index,
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.state,
    required this.canEdit,
    this.dragIndex,
  });

  final Category category;
  final CategoriesState state;
  final bool canEdit;

  /// Set for a reorderable row: shows the drag handle.
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fields = state.fieldsOf(category);
    final busy =
        state.actionStatus.isLoading &&
        state.targetId == category.id &&
        state.action != CategoryAction.reorder;
    final dragIndex = this.dragIndex;
    return AppCard(
      onTap: canEdit ? () => unawaited(_edit(context, category)) : null,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md.w,
        AppSpacing.sm.h,
        AppSpacing.xs.w,
        AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          CategoryIconBadge(
            icon: category.icon,
            colour: category.colour,
            muted: category.archived,
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: textTheme.titleSmall?.copyWith(
                    color: category.archived ? AppColors.textSecondary : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fields.isNotEmpty || category.archived)
                  Text(
                    [
                      if (category.archived) category.kind.label,
                      if (fields.isNotEmpty)
                        fields.map((field) => field.label).join(', '),
                    ].join(' · '),
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (busy)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
              child: SizedBox.square(
                dimension: 18.r,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (canEdit)
            _Menu(category: category),
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

enum _CategoryMenu { edit, archive, restore, delete }

class _Menu extends StatelessWidget {
  const _Menu({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CategoryMenu>(
      tooltip: 'Category actions',
      onSelected: (choice) => unawaited(_onSelected(context, choice)),
      itemBuilder: (_) => [
        const PopupMenuItem(value: _CategoryMenu.edit, child: Text('Edit')),
        if (category.archived)
          const PopupMenuItem(
            value: _CategoryMenu.restore,
            child: Text('Restore'),
          )
        else
          const PopupMenuItem(
            value: _CategoryMenu.archive,
            child: Text('Archive'),
          ),
        const PopupMenuItem(
          value: _CategoryMenu.delete,
          child: Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Future<void> _onSelected(BuildContext context, _CategoryMenu choice) async {
    final cubit = context.read<CategoriesCubit>();
    switch (choice) {
      case _CategoryMenu.edit:
        await _edit(context, category);
      case _CategoryMenu.archive:
        await cubit.archive(category);
      case _CategoryMenu.restore:
        await cubit.unarchive(category);
      case _CategoryMenu.delete:
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: 'Delete ${category.name}?',
          message:
              'Only possible when no transaction uses it. Archiving keeps '
              'it for past entries and hides it from new ones.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (confirmed) await cubit.delete(category);
    }
  }
}
