import 'package:business_ledger/core/firebase/firestore_read.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// `businesses/{bid}/audit/{id}` (`functions/src/lib/audit.ts`). Readable by
/// admins and owners only.
class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.action,
    this.actor = '',
    this.before = const {},
    this.after = const {},
    this.note = '',
    this.at,
  });

  factory AuditEntry.fromFirestore(DocumentSnapshot<JsonMap> doc) =>
      AuditEntry.fromMap(doc.id, doc.data() ?? const {});

  factory AuditEntry.fromMap(String id, Map<String, dynamic> map) => AuditEntry(
    id: id,
    entity: map.readString('entity'),
    entityId: map.readString('entityId'),
    action: map.readString('action'),
    actor: map.readString('actor'),
    before: map.readMap('before'),
    after: map.readMap('after'),
    note: map.readString('note'),
    at: map.readDate('at'),
  );

  final String id;
  final String entity;
  final String entityId;
  final String action;

  /// The uid that acted.
  final String actor;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final String note;
  final DateTime? at;

  /// A human label for [action].
  String get label => switch (action) {
    'confirm' => 'Confirmed',
    'confirmAndSettle' => 'Confirmed and paid',
    'edit' => 'Edited',
    'cancel' => 'Cancelled',
    'payment' => 'Payment recorded',
    'refund' => 'Refund recorded',
    'credit' => 'Credit recorded',
    _ => action,
  };

  /// The keys an edit changed, for a one-line summary.
  List<String> get changedKeys => [
    for (final key in {...before.keys, ...after.keys})
      if (!_snapshotKeys.contains(key)) key,
  ];

  static const Set<String> _snapshotKeys = {
    'categoryName',
    'partyName',
    'projectName',
  };

  @override
  List<Object?> get props => [
    id,
    entity,
    entityId,
    action,
    actor,
    before,
    after,
    note,
    at,
  ];
}
