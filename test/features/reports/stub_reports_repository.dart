import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:business_ledger/features/reports/domain/repository/reports_repository.dart';

/// Hand-written [ReportsRepository] for bloc tests. Push data through the
/// controllers; set the future results before acting.
class StubReportsRepository extends ReportsRepository {
  final StreamController<AppResult<List<DailyStats>>> stats =
      StreamController.broadcast();
  final StreamController<AppResult<List<TransactionRow>>> open =
      StreamController.broadcast();
  final StreamController<AppResult<List<TransactionRow>>> recent =
      StreamController.broadcast();

  AppResult<ReceivablesPayables> balances = const Success(
    ReceivablesPayables(receivableMinor: 50000, payableMinor: 12000),
  );
  AppResult<ReportLabels> labelsResult = const Success(
    ReportLabels(
      categories: {'c1': 'Sales', 'c2': 'Rent'},
      projects: {'p1': 'Fit-out'},
    ),
  );

  final List<(String, String)> statsQueries = [];
  int balanceCalls = 0;

  @override
  Stream<AppResult<List<DailyStats>>> watchStats(
    String businessId, {
    required String from,
    required String to,
  }) {
    statsQueries.add((from, to));
    return stats.stream;
  }

  @override
  Future<AppResult<ReceivablesPayables>> receivablesAndPayables(
    String businessId,
  ) async {
    balanceCalls++;
    return balances;
  }

  @override
  Stream<AppResult<List<TransactionRow>>> openTransactions(
    String businessId, {
    Direction? direction,
    bool overdueOnly = false,
    String? today,
    int limit = 20,
  }) => open.stream;

  @override
  Stream<AppResult<List<TransactionRow>>> recentTransactions(
    String businessId, {
    int limit = 10,
  }) => recent.stream;

  @override
  Future<AppResult<ReportLabels>> labels(String businessId) async =>
      labelsResult;

  Future<void> dispose() async {
    await stats.close();
    await open.close();
    await recent.close();
  }
}
