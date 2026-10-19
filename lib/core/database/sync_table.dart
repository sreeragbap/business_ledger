import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/row_codec.dart';
import 'package:drift/drift.dart';

/// Every table the device mirrors, with what sync needs to know about it:
/// its Postgres name, primary key columns, whether it is pulled per business
/// and whether the client may write it (`supabase/README.md`, Schema and
/// Row level security).
enum SyncTable {
  profiles('profiles', ['id'], scoped: false, writable: true),
  businesses('businesses', ['id'], scoped: false, writable: true),
  members('members', ['business_id', 'user_id']),
  categories('categories', ['id'], writable: true),
  customFields('custom_fields', ['id'], writable: true),
  parties('parties', ['id'], writable: true),
  projects('projects', ['id'], writable: true),
  transactions('transactions', ['id'], writable: true),
  settlements('settlements', ['transaction_id', 'id']),
  documents('documents', ['business_id', 'id']),
  dailyStats('daily_stats', ['business_id', 'date']),

  /// Readable by admins and owners only.
  auditLog('audit_log', ['id'], adminOnly: true);

  const SyncTable(
    this.name,
    this.keys, {
    this.scoped = true,
    this.writable = false,
    this.adminOnly = false,
  });

  /// The Postgres (and SQLite) table name.
  final String name;

  /// Primary key columns.
  final List<String> keys;

  /// Has a `business_id` and is pulled per business by `seq`.
  final bool scoped;

  /// Clients may insert/update it (under RLS); it has `local_pending`.
  final bool writable;
  final bool adminOnly;

  /// Pulled per business, in this order.
  static const List<SyncTable> perBusiness = [
    members,
    categories,
    customFields,
    parties,
    projects,
    transactions,
    settlements,
    documents,
    dailyStats,
    auditLog,
  ];

  static SyncTable byName(String name) => values.firstWhere(
    (table) => table.name == name,
    orElse: () => throw ArgumentError.value(name, 'name', 'Unknown table'),
  );

  /// The primary key values of [row].
  Map<String, Object?> keyOf(Map<String, dynamic> row) => {
    for (final key in keys) key: row[key],
  };

  /// A stable text form of [row]'s key, e.g. `categories:<uuid>`.
  String keyText(Map<String, dynamic> row) =>
      '$name:${keys.map((key) => '${row[key]}').join('|')}';

  TableInfo<Table, Object?> info(AppDatabase db) => switch (this) {
    profiles => db.profiles,
    businesses => db.businesses,
    members => db.members,
    categories => db.categories,
    customFields => db.customFields,
    parties => db.parties,
    projects => db.projects,
    transactions => db.transactions,
    settlements => db.settlements,
    documents => db.documents,
    dailyStats => db.dailyStatsTable,
    auditLog => db.auditLog,
  };

  /// A drift row from a row map (`RowCodec`): what an upsert stores.
  Insertable<Object?> insertable(Map<String, dynamic> row) {
    const s = RowCodec.serializer;
    return switch (this) {
      profiles => ProfileRow.fromJson(row, serializer: s),
      businesses => BusinessRow.fromJson(row, serializer: s),
      members => MemberRow.fromJson(row, serializer: s),
      categories => CategoryRow.fromJson(row, serializer: s),
      customFields => CustomFieldRow.fromJson(row, serializer: s),
      parties => PartyRow.fromJson(row, serializer: s),
      projects => ProjectRow.fromJson(row, serializer: s),
      transactions => TransactionRowData.fromJson(row, serializer: s),
      settlements => SettlementRow.fromJson(row, serializer: s),
      documents => DocumentRow.fromJson(row, serializer: s),
      dailyStats => DailyStatsRow.fromJson(row, serializer: s),
      auditLog => AuditRow.fromJson(row, serializer: s),
    };
  }
}

/// Any drift data class back to its row map.
Map<String, dynamic> rowOf(Object? data) =>
    (data! as DataClass).toJson(serializer: RowCodec.serializer);
