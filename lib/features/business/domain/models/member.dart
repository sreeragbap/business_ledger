import 'package:business_ledger/core/firebase/firestore_read.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// `businesses/{bid}/members/{uid}`. Written only by functions (`addMember`,
/// `updateMemberRole`, `removeMember`, `createBusiness`); read-only here.
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

  factory Member.fromFirestore(DocumentSnapshot<JsonMap> doc) =>
      Member.fromMap(doc.id, doc.data() ?? const {});

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
