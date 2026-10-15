import 'package:business_ledger/core/firebase/firestore_read.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/features/categories/domain/const/field_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// `businesses/{bid}/fields/{id}`: a business-defined input that categories
/// attach to the transaction form. Values live on the transaction as
/// `customFields{fieldId: value}` (see [FieldType] for each type's shape).
///
/// Never deleted, only archived, so old values keep a label.
class CustomField extends Equatable {
  const CustomField({
    required this.id,
    required this.label,
    this.type = FieldType.text,
    this.options = const [],
    this.required = false,
    this.sortOrder = 0,
    this.archived = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomField.fromFirestore(DocumentSnapshot<JsonMap> doc) =>
      CustomField.fromMap(doc.id, doc.data() ?? const {});

  factory CustomField.fromMap(String id, Map<String, dynamic> map) =>
      CustomField(
        id: id,
        label: map.readString('label'),
        type: FieldType.fromKey(map['type']),
        options: map.readStringList('options'),
        required: map.readBool('required'),
        sortOrder: map.readInt('sortOrder'),
        archived: map.readBool('archived'),
        createdAt: map.readDate('createdAt'),
        updatedAt: map.readDate('updatedAt'),
      );

  /// `shortString(label, 60)` in the rules.
  static const int maxLabelLength = 60;
  static const int maxOptions = 50;

  final String id;
  final String label;
  final FieldType type;

  /// Choices for [FieldType.select]; empty for every other type.
  final List<String> options;
  final bool required;
  final int sortOrder;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toMap() => {
    'label': label.trim(),
    'type': type.key,
    'options': type.hasOptions ? options : const <String>[],
    'required': required,
    'sortOrder': sortOrder,
    'archived': archived,
  };

  CustomField copyWith({
    String? id,
    String? label,
    FieldType? type,
    List<String>? options,
    bool? required,
    int? sortOrder,
    bool? archived,
  }) => CustomField(
    id: id ?? this.id,
    label: label ?? this.label,
    type: type ?? this.type,
    options: options ?? this.options,
    required: required ?? this.required,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    label,
    type,
    options,
    required,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
}
