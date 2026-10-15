import 'package:business_ledger/core/firebase/firestore_read.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/const/category_style.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// `businesses/{bid}/categories/{id}`. Written by clients (editor+) under
/// `validCategory` in `firestore.rules`: `name` 1–60 chars, `kind` one of
/// income/expense/any, `archived` a bool and `fieldIds` a list — [toMap]
/// always writes all four.
///
/// Archived categories stay readable by id: confirmed transactions keep a
/// `categoryName` snapshot, but a draft or a report may still resolve one.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    this.kind = CategoryKind.any,
    this.icon = CategoryIcon.receipt,
    this.colour = CategoryColour.grey,
    this.fieldIds = const [],
    this.sortOrder = 0,
    this.archived = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromFirestore(DocumentSnapshot<JsonMap> doc) =>
      Category.fromMap(doc.id, doc.data() ?? const {});

  factory Category.fromMap(String id, Map<String, dynamic> map) => Category(
    id: id,
    name: map.readString('name'),
    kind: CategoryKind.fromKey(map['kind']),
    icon: CategoryIcon.fromKey(map['icon']),
    colour: CategoryColour.fromKey(map['colour']),
    fieldIds: map.readStringList('fieldIds'),
    sortOrder: map.readInt('sortOrder'),
    archived: map.readBool('archived'),
    createdAt: map.readDate('createdAt'),
    updatedAt: map.readDate('updatedAt'),
  );

  static const int maxNameLength = 60;

  final String id;
  final String name;
  final CategoryKind kind;
  final CategoryIcon icon;
  final CategoryColour colour;

  /// Custom fields shown on the transaction form for this category, in the
  /// order chosen here.
  final List<String> fieldIds;
  final int sortOrder;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The client-owned fields. Timestamps are added by the service as server
  /// timestamps.
  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'kind': kind.key,
    'icon': icon.key,
    'colour': colour.key,
    'fieldIds': fieldIds,
    'sortOrder': sortOrder,
    'archived': archived,
  };

  Category copyWith({
    String? id,
    String? name,
    CategoryKind? kind,
    CategoryIcon? icon,
    CategoryColour? colour,
    List<String>? fieldIds,
    int? sortOrder,
    bool? archived,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    icon: icon ?? this.icon,
    colour: colour ?? this.colour,
    fieldIds: fieldIds ?? this.fieldIds,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    kind,
    icon,
    colour,
    fieldIds,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
}
