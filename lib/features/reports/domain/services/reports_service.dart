import 'dart:async';

import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:business_ledger/features/reports/domain/repository/reports_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

/// [ReportsRepository] over the on-device store: `daily_stats` rows and
/// the transactions pulled from Supabase. Works offline; figures are as of
/// the last pull.
@LazySingleton(as: ReportsRepository)
class ReportsService implements ReportsRepository {
  ReportsService(this._store, this._engine);

  final LocalStore _store;
  final SyncEngine _engine;

  AppDatabase get _db => _store.db;

  @override
  Stream<AppResult<List<DailyStats>>> watchStats(
    String businessId, {
    required String from,
    required String to,
  }) => LocalStreams.watch(
    (_db.select(_db.dailyStatsTable)
          ..where(
            (s) =>
                s.businessId.equals(businessId) &
                s.date.isBiggerOrEqualValue(from) &
                s.date.isSmallerOrEqualValue(to),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .watch(),
    (rows) => [for (final row in rows) DailyStats.fromRow(rowOf(row))],
  );

  /// `sum(outstanding_minor)` per direction over open (confirmed, owed)
  /// transactions, summed by SQLite in integers: never a double.
  @override
  Future<AppResult<ReceivablesPayables>> receivablesAndPayables(
    String businessId,
  ) => AppResult.guard(() async {
    final row = await _db
        .customSelect(
          'SELECT '
          "COALESCE(SUM(CASE WHEN direction = 'in' "
          'THEN outstanding_minor END), 0) AS receivable, '
          "COALESCE(SUM(CASE WHEN direction = 'out' "
          'THEN outstanding_minor END), 0) AS payable '
          'FROM transactions '
          'WHERE business_id = ? AND is_open = 1 AND deleted_at IS NULL',
          variables: [Variable.withString(businessId)],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    return ReceivablesPayables(
      receivableMinor: row.read<int>('receivable'),
      payableMinor: row.read<int>('payable'),
    );
  });

  @override
  Stream<AppResult<List<TransactionRow>>> openTransactions(
    String businessId, {
    Direction? direction,
    bool overdueOnly = false,
    String? today,
    int limit = 20,
  }) {
    final day = today ?? CalendarDay.key(CalendarDay.today());
    final query = _db.select(_db.transactions)
      ..where((t) {
        var where =
            t.businessId.equals(businessId) &
            t.isOpen.equals(true) &
            t.deletedAt.isNull();
        if (direction != null) where &= t.direction.equals(direction.key);
        if (overdueOnly) where &= t.dueDate.isSmallerThanValue(day);
        return where;
      })
      ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
      ..limit(limit);
    return LocalStreams.watch(query.watch(), _rows);
  }

  @override
  Stream<AppResult<List<TransactionRow>>> recentTransactions(
    String businessId, {
    int limit = 10,
  }) => LocalStreams.watch(
    (_db.select(_db.transactions)
          ..where((t) => t.businessId.equals(businessId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAt),
          ])
          ..limit(limit))
        .watch(),
    _rows,
  );

  @override
  Future<AppResult<ReportLabels>> labels(String businessId) =>
      AppResult.guard(() async {
        final categories =
            await (_db.select(_db.categories)..where(
                  (c) => c.businessId.equals(businessId) & c.deletedAt.isNull(),
                ))
                .get();
        final projects = await (_db.select(
          _db.projects,
        )..where((p) => p.businessId.equals(businessId))).get();
        return ReportLabels(
          categories: {for (final c in categories) c.id: c.name},
          projects: {for (final p in projects) p.id: p.name},
        );
      });

  @override
  Future<void> refresh() async {
    try {
      await _engine.refresh().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // The live figures update by themselves when the pull lands.
    }
  }

  static List<TransactionRow> _rows(List<TransactionRowData> rows) => [
    for (final row in rows) TransactionRow.fromRow(rowOf(row)),
  ];
}
