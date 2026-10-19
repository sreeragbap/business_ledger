import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:equatable/equatable.dart';

/// A `parties` row: a customer, a supplier, or both. The table requires
/// `name` (≤ 120 chars) and a valid `kind`. Archived, never
/// deleted: transactions keep a `partyName` snapshot.
class Party extends Equatable {
  const Party({
    required this.id,
    required this.name,
    this.kind = PartyKind.customer,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.archived = false,
    this.createdAt,
    this.updatedAt,
  });

  /// A Postgres row (snake_case).
  factory Party.fromRow(Map<String, dynamic> row) =>
      Party.fromMap(row.readString('id'), RowKeys.camelMap(row));

  factory Party.fromMap(String id, Map<String, dynamic> map) => Party(
    id: id,
    name: map.readString('name'),
    kind: PartyKind.fromKey(map['kind']),
    phone: map.readString('phone'),
    email: map.readString('email'),
    address: map.readString('address'),
    archived: map.readBool('archived'),
    createdAt: map.readDate('createdAt'),
    updatedAt: map.readDate('updatedAt'),
  );

  static const int maxNameLength = 120;

  final String id;
  final String name;
  final PartyKind kind;
  final String phone;
  final String email;
  final String address;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Case-insensitive match on name, phone or email. Parties are searched
  /// on the device: a business has hundreds, not millions, and the list is
  /// already cached for offline use.
  bool matchesQuery(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        email.toLowerCase().contains(needle) ||
        phone
            .replaceAll(RegExp(r'\s'), '')
            .contains(needle.replaceAll(' ', ''));
  }

  Map<String, Object?> toMap() => {
    'name': name.trim(),
    'kind': kind.key,
    'phone': phone.trim(),
    'email': email.trim(),
    'address': address.trim(),
    'archived': archived,
  };

  /// The row a client writes (insert or update) for [businessId].
  Map<String, Object?> toRow(String businessId) => {
    'id': id,
    'business_id': businessId,
    ...RowKeys.snakeMap(toMap()),
  };

  Party copyWith({
    String? id,
    String? name,
    PartyKind? kind,
    String? phone,
    String? email,
    String? address,
    bool? archived,
  }) => Party(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    kind,
    phone,
    email,
    address,
    archived,
    createdAt,
    updatedAt,
  ];
}
