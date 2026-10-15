part of 'categories_cubit.dart';

enum CategoryAction { save, reorder, archive, unarchive, delete }

class CategoriesState extends Equatable {
  const CategoriesState({
    this.categories,
    this.fields = const [],
    this.loadStatus = const Status.initial(),
    this.action,
    this.targetId,
    this.actionStatus = const Status.initial(),
  });

  /// Every category, archived included, by `sortOrder`. `null` until the
  /// first snapshot.
  final List<Category>? categories;

  /// Every custom field, for the attach picker and labels.
  final List<CustomField> fields;
  final Status loadStatus;

  final CategoryAction? action;
  final String? targetId;
  final Status actionStatus;

  List<Category> get active => _sorted(
    (categories ?? const <Category>[]).where((item) => !item.archived),
  );

  List<Category> get archived => _sorted(
    (categories ?? const <Category>[]).where((item) => item.archived),
  );

  List<Category> activeOf(CategoryKind kind) =>
      active.where((item) => item.kind == kind).toList(growable: false);

  List<CustomField> get activeFields =>
      fields.where((field) => !field.archived).toList(growable: false);

  /// Field ids of [category] resolved to fields, in its order, skipping
  /// ids that no longer resolve.
  List<CustomField> fieldsOf(Category category) {
    final byId = {for (final field in fields) field.id: field};
    return [
      for (final id in category.fieldIds) ?byId[id],
    ];
  }

  /// The last delete was refused because transactions use the category.
  bool get deleteBlockedByUse =>
      action == CategoryAction.delete &&
      actionStatus.isFailure &&
      actionStatus.error?.kind == AppErrorKind.inUse;

  static List<Category> _sorted(Iterable<Category> items) =>
      List<Category>.of(items)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  CategoriesState copyWith({
    List<Category>? categories,
    List<CustomField>? fields,
    Status? loadStatus,
    CategoryAction? action,
    String? targetId,
    Status? actionStatus,
  }) => CategoriesState(
    categories: categories ?? this.categories,
    fields: fields ?? this.fields,
    loadStatus: loadStatus ?? this.loadStatus,
    action: action ?? this.action,
    targetId: action != null ? targetId : this.targetId,
    actionStatus: actionStatus ?? this.actionStatus,
  );

  @override
  List<Object?> get props => [
    categories,
    fields,
    loadStatus,
    action,
    targetId,
    actionStatus,
  ];
}
