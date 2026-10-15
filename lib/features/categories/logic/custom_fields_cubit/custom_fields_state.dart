part of 'custom_fields_cubit.dart';

enum FieldAction { save, reorder, archive, unarchive }

class CustomFieldsState extends Equatable {
  const CustomFieldsState({
    this.fields,
    this.loadStatus = const Status.initial(),
    this.action,
    this.targetId,
    this.actionStatus = const Status.initial(),
  });

  /// Every field, archived included. `null` until the first snapshot.
  final List<CustomField>? fields;
  final Status loadStatus;
  final FieldAction? action;
  final String? targetId;
  final Status actionStatus;

  List<CustomField> get active => _sorted(
    (fields ?? const <CustomField>[]).where((field) => !field.archived),
  );

  List<CustomField> get archived => _sorted(
    (fields ?? const <CustomField>[]).where((field) => field.archived),
  );

  static List<CustomField> _sorted(Iterable<CustomField> items) =>
      List<CustomField>.of(items)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  CustomFieldsState copyWith({
    List<CustomField>? fields,
    Status? loadStatus,
    FieldAction? action,
    String? targetId,
    Status? actionStatus,
  }) => CustomFieldsState(
    fields: fields ?? this.fields,
    loadStatus: loadStatus ?? this.loadStatus,
    action: action ?? this.action,
    targetId: action != null ? targetId : this.targetId,
    actionStatus: actionStatus ?? this.actionStatus,
  );

  @override
  List<Object?> get props => [
    fields,
    loadStatus,
    action,
    targetId,
    actionStatus,
  ];
}
