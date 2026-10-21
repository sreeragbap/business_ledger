import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/close_guard.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/domain/sort_orders.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/domain/repository/category_repository.dart';
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'categories_state.dart';

/// The categories screen: a live list (with the custom fields categories can
/// attach), create/edit, drag-to-reorder within a kind, archive, delete.
///
/// Reorders are applied to the state at once and written as one batch of
/// only the changed `sortOrder`s; the listener then confirms them.
@injectable
class CategoriesCubit extends Cubit<CategoriesState>
    with CloseGuard<CategoriesState> {
  CategoriesCubit(this._categories, this._fields)
    : super(const CategoriesState());

  final CategoryRepository _categories;
  final CustomFieldRepository _fields;
  StreamSubscription<AppResult<List<Category>>>? _categorySubscription;
  StreamSubscription<AppResult<List<CustomField>>>? _fieldSubscription;
  String? _businessId;

  Future<void> watch(String businessId) async {
    _businessId = businessId;
    await _categorySubscription?.cancel();
    await _fieldSubscription?.cancel();
    if (isClosing) return;
    emit(state.copyWith(loadStatus: const Status.loading()));
    _categorySubscription = _categories
        .watchCategories(businessId)
        .listen(
          (result) => emit(
            result.when(
              success: (categories) => state.copyWith(
                categories: categories,
                loadStatus: const Status.success(),
              ),
              failure: (error) =>
                  state.copyWith(loadStatus: Status.fromException(error)),
            ),
          ),
        );
    _fieldSubscription = _fields
        .watchFields(businessId)
        .listen(
          (result) => result.when(
            success: (fields) => emit(state.copyWith(fields: fields)),
            // Fields are an extra here; the category list stands without them.
            failure: (_) {},
          ),
        );
  }

  /// Creates [category] when its id is empty, otherwise updates it.
  Future<void> save(Category category) async {
    final name = category.name.trim();
    if (name.isEmpty || name.length > Category.maxNameLength) {
      final message = name.isEmpty
          ? 'Give the category a name.'
          : 'Keep the name under ${Category.maxNameLength} characters.';
      emit(
        state.copyWith(
          action: CategoryAction.save,
          actionStatus: Status.failure(
            message,
            errors: {
              'name': [message],
            },
          ),
        ),
      );
      return;
    }
    final isNew = category.id.isEmpty;
    await _run(
      CategoryAction.save,
      category.id,
      (businessId) => isNew
          ? _categories.create(
              businessId,
              category.copyWith(
                name: name,
                sortOrder: SortOrders.next(
                  state.categories ?? const <Category>[],
                  (item) => item.sortOrder,
                ),
              ),
            )
          : _categories.update(businessId, category.copyWith(name: name)),
      isNew ? 'Category added.' : 'Category saved.',
    );
  }

  /// Moves an active category of [kind] from [oldIndex] to [newIndex]
  /// (`ReorderableListView.onReorderItem` indices within that kind's section).
  Future<void> reorder(CategoryKind kind, int oldIndex, int newIndex) async {
    final businessId = _businessId;
    final all = state.categories;
    if (businessId == null || all == null) return;

    final active = state.active;
    final group = active.where((item) => item.kind == kind).toList();
    final moved = SortOrders.move(group, oldIndex, newIndex);
    final ordered = SortOrders.mergeGroup(active, moved, (item) => item.id);
    final changes = SortOrders.changes(
      ordered,
      (item) => item.id,
      (item) => item.sortOrder,
    );
    if (changes.isEmpty) return;

    // Optimistic: the list settles under the finger, not after a round trip.
    final updated = [
      for (final item in ordered)
        item.copyWith(sortOrder: changes[item.id] ?? item.sortOrder),
      ...all.where((item) => item.archived),
    ];
    emit(
      state.copyWith(
        categories: updated,
        action: CategoryAction.reorder,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await _categories.reorder(businessId, changes);
    emit(
      state.copyWith(
        actionStatus: result.when(
          success: (_) => const Status.success(),
          failure: Status.fromException,
        ),
      ),
    );
  }

  Future<void> archive(Category category) => _run(
    CategoryAction.archive,
    category.id,
    (businessId) =>
        _categories.setArchived(businessId, category.id, archived: true),
    '${category.name} archived. It still shows on past entries.',
  );

  /// Restores [category] to the end of the list.
  Future<void> unarchive(Category category) => _run(
    CategoryAction.unarchive,
    category.id,
    (businessId) => _categories.setArchived(
      businessId,
      category.id,
      archived: false,
      sortOrder: SortOrders.next(state.active, (item) => item.sortOrder),
    ),
    '${category.name} restored.',
  );

  /// Fails with [AppErrorKind.inUse] when transactions use it; check
  /// [CategoriesState.deleteBlockedByUse] to offer archiving instead.
  Future<void> delete(Category category) => _run(
    CategoryAction.delete,
    category.id,
    (businessId) => _categories.delete(businessId, category.id),
    '${category.name} deleted.',
  );

  Future<void> _run<T>(
    CategoryAction action,
    String? targetId,
    Future<AppResult<T>> Function(String businessId) call,
    String successMessage,
  ) async {
    final businessId = _businessId;
    if (businessId == null) return;
    emit(
      state.copyWith(
        action: action,
        targetId: targetId,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await call(businessId);
    emit(
      state.copyWith(
        actionStatus: result.when(
          success: (_) => Status.success(message: successMessage),
          failure: Status.fromException,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    beginClose();
    await _categorySubscription?.cancel();
    await _fieldSubscription?.cancel();
    return super.close();
  }
}
