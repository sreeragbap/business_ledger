import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';

/// Read-only access to the figures the dashboard and reports show.
abstract class ReportsRepository {
  const ReportsRepository();

  /// Stats days from [from] to [to] (`yyyy-MM-dd`, inclusive), oldest first.
  /// Days without activity have no row and are simply absent.
  Stream<AppResult<List<DailyStats>>> watchStats(
    String businessId, {
    required String from,
    required String to,
  });

  /// `sum(outstandingMinor)` over open transactions, per direction, from
  /// the on-device store.
  Future<AppResult<ReceivablesPayables>> receivablesAndPayables(
    String businessId,
  );

  /// Open (confirmed, unsettled) transactions by due date, earliest first.
  /// With [overdueOnly], only those due before [today] (`yyyy-MM-dd`).
  Stream<AppResult<List<TransactionRow>>> openTransactions(
    String businessId, {
    Direction? direction,
    bool overdueOnly = false,
    String? today,
    int limit = 20,
  });

  /// The latest transactions by date, newest first.
  Stream<AppResult<List<TransactionRow>>> recentTransactions(
    String businessId, {
    int limit = 10,
  });

  /// Category and project names, to label the ids found in stats.
  Future<AppResult<ReportLabels>> labels(String businessId);

  /// Pull-to-refresh: asks the server for what changed. Completes when
  /// done, or at once when unreachable.
  Future<void> refresh() async {}
}
