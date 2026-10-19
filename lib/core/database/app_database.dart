import 'package:business_ledger/core/database/row_codec.dart';
import 'package:business_ledger/core/database/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The on-device store (SQLite through drift): every screen reads from it,
/// so the app works fully offline. The sync engine fills it from Supabase
/// and the services write drafts and settings into it before they are
/// pushed (`docs/ARCHITECTURE.md` §2).
@DriftDatabase(
  tables: [
    Profiles,
    Businesses,
    Members,
    Categories,
    CustomFields,
    Parties,
    Projects,
    Transactions,
    Settlements,
    Documents,
    AuditLog,
    DailyStatsTable,
    SyncCursors,
    LocalMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The app's database file, `ledger.sqlite` in the app support directory.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'ledger',
      native: const DriftNativeOptions(
        databaseDirectory: _supportDirectory,
      ),
    ),
  );

  @override
  int get schemaVersion => 1;

  /// Every synced table, for wiping a business or the whole store.
  List<TableInfo<Table, Object?>> get syncedTables => [
    profiles,
    businesses,
    members,
    categories,
    customFields,
    parties,
    projects,
    transactions,
    settlements,
    documents,
    auditLog,
    dailyStatsTable,
  ];
}

/// App support rather than documents: not user-visible, and not purged by
/// the OS like the cache directory.
Future<Object> _supportDirectory() => getApplicationSupportDirectory();
