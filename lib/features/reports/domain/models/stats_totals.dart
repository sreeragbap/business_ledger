import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:equatable/equatable.dart';

/// Daily stats summed over a period. All figures are minor units.
///
/// Income/expense (recognised, by transaction date) and cash (received /
/// paid, by settlement date) are different questions and are kept apart:
/// a sale on credit is income today and cash later.
class StatsTotals extends Equatable {
  const StatsTotals({
    this.incomeMinor = 0,
    this.expenseMinor = 0,
    this.cashInMinor = 0,
    this.cashOutMinor = 0,
    this.byCategory = const {},
    this.byProject = const {},
    this.byType = const {},
    this.days = 0,
  });

  static const StatsTotals zero = StatsTotals();

  final int incomeMinor;
  final int expenseMinor;
  final int cashInMinor;
  final int cashOutMinor;
  final Map<String, InOut> byCategory;
  final Map<String, InOut> byProject;
  final Map<String, InOut> byType;

  /// How many stats days contributed (days with no activity have no doc).
  final int days;

  /// Income − expense.
  int get netMinor => incomeMinor - expenseMinor;

  /// Cash received − cash paid.
  int get netCashMinor => cashInMinor - cashOutMinor;

  bool get isEmpty =>
      incomeMinor == 0 &&
      expenseMinor == 0 &&
      cashInMinor == 0 &&
      cashOutMinor == 0;

  @override
  List<Object?> get props => [
    incomeMinor,
    expenseMinor,
    cashInMinor,
    cashOutMinor,
    byCategory,
    byProject,
    byType,
    days,
  ];
}
