import 'package:business_ledger/core/database/row_codec.dart';
import 'package:drift/drift.dart';

// The on-device copy of the Supabase tables the app reads
// (`supabase/migrations/*_tables.sql`). Column names are the Postgres ones
// (drift snake_cases the getters), types follow `RowCodec`: text for uuids,
// dates and timestamps; int for money (minor units) and counters; JSON text
// for jsonb and array columns.
//
// `local_pending` (client-writable tables only) is not a server column: it
// marks a row changed on this device whose change is still in the outbox.
// Rows that do not exist on the server have the same shape, with the
// server-maintained columns at their zero values.

/// `profiles`: only the signed-in user's own row.
@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get photoUrl => text().withDefault(const Constant(''))();
  TextColumn get lastBusinessId => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  BoolColumn get localPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BusinessRow')
class Businesses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get currencyCode => text().withDefault(const Constant(''))();
  IntColumn get currencyDecimals => integer().withDefault(const Constant(2))();
  TextColumn get currencySymbol => text().withDefault(const Constant(''))();
  TextColumn get timezone => text().withDefault(const Constant(''))();
  TextColumn get template => text().withDefault(const Constant(''))();
  TextColumn get ownerId => text().withDefault(const Constant(''))();
  TextColumn get settings =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  BoolColumn get localPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MemberRow')
@TableIndex(name: 'members_user_idx', columns: {#userId})
class Members extends Table {
  TextColumn get businessId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text().withDefault(const Constant('viewer'))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get photoUrl => text().withDefault(const Constant(''))();
  TextColumn get addedBy => text().nullable()();
  TextColumn get addedAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {businessId, userId};
}

@DataClassName('CategoryRow')
@TableIndex(name: 'categories_business_idx', columns: {#businessId})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get kind => text().withDefault(const Constant('any'))();
  TextColumn get icon => text().withDefault(const Constant(''))();
  TextColumn get colour => text().withDefault(const Constant(''))();
  TextColumn get fieldIds =>
      text().map(const JsonListConverter()).withDefault(const Constant('[]'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  BoolColumn get localPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('CustomFieldRow')
@TableIndex(name: 'custom_fields_business_idx', columns: {#businessId})
class CustomFields extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('text'))();
  TextColumn get options =>
      text().map(const JsonListConverter()).withDefault(const Constant('[]'))();
  BoolColumn get required => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  BoolColumn get localPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PartyRow')
@TableIndex(name: 'parties_business_idx', columns: {#businessId})
class Parties extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get kind => text().withDefault(const Constant('customer'))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  BoolColumn get localPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProjectRow')
@TableIndex(name: 'projects_business_idx', columns: {#businessId})
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get code => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  BoolColumn get localPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionRowData')
@TableIndex(name: 'transactions_date_idx', columns: {#businessId, #date})
@TableIndex(name: 'transactions_open_idx', columns: {#businessId, #isOpen})
@TableIndex(name: 'transactions_linked_idx', columns: {#linkedTransactionId})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  TextColumn get direction => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  TextColumn get partyId => text().nullable()();
  TextColumn get partyName => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get projectName => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get reference => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get paymentMethod => text().withDefault(const Constant(''))();

  /// `yyyy-MM-dd`: compares and sorts as text.
  TextColumn get date => text().nullable()();
  TextColumn get dueDate => text().nullable()();
  TextColumn get lineItems =>
      text().map(const JsonListConverter()).withDefault(const Constant('[]'))();
  IntColumn get totalMinor => integer().withDefault(const Constant(0))();
  IntColumn get paidMinor => integer().withDefault(const Constant(0))();
  IntColumn get refundedMinor => integer().withDefault(const Constant(0))();
  IntColumn get creditedMinor => integer().withDefault(const Constant(0))();
  IntColumn get effectiveMinor => integer().withDefault(const Constant(0))();
  IntColumn get outstandingMinor => integer().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text().nullable()();
  BoolColumn get isOpen => boolean().withDefault(const Constant(false))();
  TextColumn get customFields =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get linkedTransactionId => text().nullable()();
  TextColumn get linkKind => text().nullable()();
  TextColumn get settlementId => text().nullable()();

  /// A JSON array of lowercase word prefixes; searched with `json_each`.
  TextColumn get searchTokens =>
      text().map(const JsonListConverter()).withDefault(const Constant('[]'))();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get createdBy => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  TextColumn get confirmedAt => text().nullable()();
  TextColumn get confirmedBy => text().nullable()();
  TextColumn get cancelledAt => text().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get deletedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();
  BoolColumn get localPending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SettlementRow')
@TableIndex(name: 'settlements_business_idx', columns: {#businessId})
class Settlements extends Table {
  TextColumn get businessId => text()();
  TextColumn get transactionId => text()();
  TextColumn get id => text()();
  TextColumn get kind => text().withDefault(const Constant('payment'))();
  IntColumn get amountMinor => integer().withDefault(const Constant(0))();
  TextColumn get date => text().withDefault(const Constant(''))();
  TextColumn get method => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get balanceAfter =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get linkedTransactionId => text().nullable()();
  TextColumn get createdBy => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text().nullable()();
  BoolColumn get voided => boolean().withDefault(const Constant(false))();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, id};
}

@DataClassName('DocumentRow')
@TableIndex(name: 'documents_transaction_idx', columns: {#transactionId})
class Documents extends Table {
  TextColumn get businessId => text()();
  TextColumn get id => text()();
  TextColumn get type => text().withDefault(const Constant('invoice'))();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get transactionId => text().withDefault(const Constant(''))();
  TextColumn get settlementId => text().nullable()();
  TextColumn get snapshot =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get issuedAt => text().nullable()();
  TextColumn get issuedBy => text().nullable()();
  BoolColumn get voided => boolean().withDefault(const Constant(false))();
  TextColumn get voidedAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {businessId, id};
}

/// `audit_log`: pulled for admins and owners only (RLS hides it otherwise).
@DataClassName('AuditRow')
@TableIndex(name: 'audit_entity_idx', columns: {#businessId, #entityId})
class AuditLog extends Table {
  IntColumn get id => integer()();
  TextColumn get businessId => text()();
  TextColumn get entity => text().withDefault(const Constant(''))();
  TextColumn get entityId => text().withDefault(const Constant(''))();
  TextColumn get action => text().withDefault(const Constant(''))();
  TextColumn get actor => text().withDefault(const Constant(''))();
  TextColumn get before =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get after =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get note => text().nullable()();
  TextColumn get at => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// `daily_stats`. Named apart from the `DailyStats` model.
@DataClassName('DailyStatsRow')
class DailyStatsTable extends Table {
  @override
  String get tableName => 'daily_stats';

  TextColumn get businessId => text()();

  /// `yyyy-MM-dd`.
  TextColumn get date => text()();
  IntColumn get incomeMinor => integer().withDefault(const Constant(0))();
  IntColumn get expenseMinor => integer().withDefault(const Constant(0))();
  IntColumn get cashInMinor => integer().withDefault(const Constant(0))();
  IntColumn get cashOutMinor => integer().withDefault(const Constant(0))();
  TextColumn get byCategory =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get byProject =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get byType =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  TextColumn get updatedAt => text().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {businessId, date};
}

/// Pull progress: the highest `seq` applied per business and table
/// (`supabase/README.md`, Sync). Local only.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  TextColumn get businessId => text()();
  TextColumn get tableKey => text().named('table_name')();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {businessId, tableKey};
}

/// Small local facts, e.g. whose data this store holds. Local only.
@DataClassName('LocalMetaRow')
class LocalMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
