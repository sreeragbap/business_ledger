import 'package:business_ledger/core/domain/json_read.dart';
import 'package:equatable/equatable.dart';

/// A `projects` row: a job, site or engagement that transactions can be
/// tagged with (and reported by, `daily_stats.by_project`). The table
/// requires `name` (≤ 120 chars). Archived, never deleted.
class Project extends Equatable {
  const Project({
    required this.id,
    required this.name,
    this.code = '',
    this.description = '',
    this.archived = false,
    this.createdAt,
    this.updatedAt,
  });

  /// A Postgres row (snake_case).
  factory Project.fromRow(Map<String, dynamic> row) =>
      Project.fromMap(row.readString('id'), RowKeys.camelMap(row));

  factory Project.fromMap(String id, Map<String, dynamic> map) => Project(
    id: id,
    name: map.readString('name'),
    code: map.readString('code'),
    description: map.readString('description'),
    archived: map.readBool('archived'),
    createdAt: map.readDate('createdAt'),
    updatedAt: map.readDate('updatedAt'),
  );

  static const int maxNameLength = 120;
  static const int maxCodeLength = 24;

  final String id;
  final String name;

  /// A short reference such as `SITE-12`. Optional.
  final String code;
  final String description;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// `SITE-12 · Villa extension`, or just the name.
  String get displayName => code.trim().isEmpty ? name : '$code · $name';

  bool matchesQuery(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        code.toLowerCase().contains(needle);
  }

  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'code': code.trim(),
    'description': description.trim(),
    'archived': archived,
  };

  /// The row a client writes (insert or update) for [businessId].
  Map<String, Object?> toRow(String businessId) => {
    'id': id,
    'business_id': businessId,
    ...RowKeys.snakeMap(toMap()),
  };

  Project copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    bool? archived,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    description: description ?? this.description,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    description,
    archived,
    createdAt,
    updatedAt,
  ];
}
