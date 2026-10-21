import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/close_guard.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/domain/sort_orders.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'custom_fields_state.dart';

/// The custom fields screen: live list, create/edit, reorder, archive.
@injectable
class CustomFieldsCubit extends Cubit<CustomFieldsState>
    with CloseGuard<CustomFieldsState> {
  CustomFieldsCubit(this._repository) : super(const CustomFieldsState());

  final CustomFieldRepository _repository;
  StreamSubscription<AppResult<List<CustomField>>>? _subscription;
  String? _businessId;

  Future<void> watch(String businessId) async {
    _businessId = businessId;
    await _subscription?.cancel();
    if (isClosing) return;
    emit(state.copyWith(loadStatus: const Status.loading()));
    _subscription = _repository
        .watchFields(businessId)
        .listen(
          (result) => emit(
            result.when(
              success: (fields) => state.copyWith(
                fields: fields,
                loadStatus: const Status.success(),
              ),
              failure: (error) =>
                  state.copyWith(loadStatus: Status.fromException(error)),
            ),
          ),
        );
  }

  /// Field errors for [field], mirroring the rules' limits.
  static Map<String, List<String>> validate(CustomField field) {
    final label = field.label.trim();
    final options = field.options.map((option) => option.trim()).toList();
    return {
      if (label.isEmpty)
        'label': ['Give the field a name.']
      else if (label.length > CustomField.maxLabelLength)
        'label': ['Keep it under ${CustomField.maxLabelLength} characters.'],
      if (field.type.hasOptions && options.isEmpty)
        'options': ['Add at least one choice.']
      else if (field.type.hasOptions &&
          options.toSet().length != options.length)
        'options': ['Each choice must be different.']
      else if (options.length > CustomField.maxOptions)
        'options': ['Keep it to ${CustomField.maxOptions} choices.'],
    };
  }

  /// Creates [field] when its id is empty, otherwise updates it.
  Future<void> save(CustomField field) async {
    final errors = validate(field);
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          action: FieldAction.save,
          actionStatus: Status.failure(
            errors.values.first.first,
            errors: errors,
          ),
        ),
      );
      return;
    }
    final clean = field.copyWith(
      label: field.label.trim(),
      options: field.type.hasOptions
          ? field.options.map((option) => option.trim()).toList()
          : const [],
    );
    final isNew = field.id.isEmpty;
    await _run(
      FieldAction.save,
      field.id,
      (businessId) => isNew
          ? _repository.create(
              businessId,
              clean.copyWith(
                sortOrder: SortOrders.next(
                  state.fields ?? const <CustomField>[],
                  (item) => item.sortOrder,
                ),
              ),
            )
          : _repository.update(businessId, clean),
      isNew ? 'Field added.' : 'Field saved.',
    );
  }

  /// `ReorderableListView.onReorderItem` indices within
  /// [CustomFieldsState.active].
  Future<void> reorder(int oldIndex, int newIndex) async {
    final businessId = _businessId;
    final all = state.fields;
    if (businessId == null || all == null) return;
    final ordered = SortOrders.move(state.active, oldIndex, newIndex);
    final changes = SortOrders.changes(
      ordered,
      (item) => item.id,
      (item) => item.sortOrder,
    );
    if (changes.isEmpty) return;
    emit(
      state.copyWith(
        fields: [
          for (final item in ordered)
            item.copyWith(sortOrder: changes[item.id] ?? item.sortOrder),
          ...all.where((item) => item.archived),
        ],
        action: FieldAction.reorder,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await _repository.reorder(businessId, changes);
    emit(
      state.copyWith(
        actionStatus: result.when(
          success: (_) => const Status.success(),
          failure: Status.fromException,
        ),
      ),
    );
  }

  Future<void> archive(CustomField field) => _run(
    FieldAction.archive,
    field.id,
    (businessId) =>
        _repository.setArchived(businessId, field.id, archived: true),
    '${field.label} archived. Past values keep their label.',
  );

  Future<void> unarchive(CustomField field) => _run(
    FieldAction.unarchive,
    field.id,
    (businessId) => _repository.setArchived(
      businessId,
      field.id,
      archived: false,
      sortOrder: SortOrders.next(state.active, (item) => item.sortOrder),
    ),
    '${field.label} restored.',
  );

  Future<void> _run<T>(
    FieldAction action,
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
    await _subscription?.cancel();
    return super.close();
  }
}
