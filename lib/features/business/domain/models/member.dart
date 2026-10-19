import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:equatable/equatable.dart';

/// A `members` row. Written only by RPCs (`add_member`,
/// `update_member_role`, `remove_member`, `create_business`); read-only
/// here.
class Member extends Equatable {
  const Member({
    required this.uid,
    required this.role,
    this.email = '',
    this.displayName = '',
    this.photoUrl = '',
    this.addedBy = '',
    this.addedAt,
  });

  /// A Postgres row (snake_case).
  factory Member.fromRow(Map<String, dynamic> row) =>
      Member.fromMap(row.readString('user_id'), RowKeys.camelMap(row));

  factory Member.fromMap(String uid, Map<String, dynamic> map) => Member(
    uid: uid,
    role: Role.fromKey(map['role']),
    email: map.readString('email'),
    displayName: map.readString('displayName'),
    photoUrl: map.readString('photoUrl'),
    addedBy: map.readString('addedBy'),
    addedAt: map.readDate('addedAt'),
  );

  final String uid;
  final Role role;
  final String email;
  final String displayName;
  final String photoUrl;
  final String addedBy;
  final DateTime? addedAt;

  String get name => displayName.trim().isNotEmpty
      ? displayName.trim()
      : email.trim().isNotEmpty
      ? email.trim()
      : 'Member';

  String get initials {
    final words = name
        .split(RegExp(r'[\s@._-]+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final value = words.map((word) => word[0].toUpperCase()).join();
    return value.isEmpty ? '?' : value;
  }

  Map<String, Object?> toMap() => {
    'role': role.key,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'addedBy': addedBy,
  };

  @override
  List<Object?> get props => [
    uid,
    role,
    email,
    displayName,
    photoUrl,
    addedBy,
    addedAt,
  ];
}
