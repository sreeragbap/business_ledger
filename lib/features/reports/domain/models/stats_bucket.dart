import 'package:equatable/equatable.dart';

enum ReportGranularity {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly');

  const ReportGranularity(this.label);
  final String label;
}

/// One bar group of a chart: a day, an ISO week (from Monday) or a month.
class StatsBucket extends Equatable {
  const StatsBucket({
    required this.start,
    required this.end,
    required this.label,
    this.incomeMinor = 0,
    this.expenseMinor = 0,
    this.cashInMinor = 0,
    this.cashOutMinor = 0,
  });

  /// UTC midnight of the bucket's first day (a Monday for weeks, the 1st for
  /// months), even when the report range starts later.
  final DateTime start;

  /// UTC midnight of the bucket's last day.
  final DateTime end;

  /// Short axis label: `14 Oct`, `W42`, `Oct`.
  final String label;
  final int incomeMinor;
  final int expenseMinor;
  final int cashInMinor;
  final int cashOutMinor;

  int get netMinor => incomeMinor - expenseMinor;

  @override
  List<Object?> get props => [
    start,
    end,
    label,
    incomeMinor,
    expenseMinor,
    cashInMinor,
    cashOutMinor,
  ];

  @override
  String toString() =>
      'StatsBucket($label: +$incomeMinor -$expenseMinor '
      'cash +$cashInMinor -$cashOutMinor)';
}

/// One row of a category / project breakdown.
class BreakdownEntry extends Equatable {
  const BreakdownEntry({
    required this.id,
    required this.label,
    required this.amountMinor,
    required this.shareBasisPoints,
  });

  final String id;
  final String label;
  final int amountMinor;

  /// Share of the total in basis points (10000 = 100%). The entries of one
  /// breakdown sum to exactly 10000 when the total is positive.
  final int shareBasisPoints;

  /// `42.5%`. Formatting only; the value itself is an integer.
  String get sharePercent {
    final whole = shareBasisPoints ~/ 100;
    final tenth = (shareBasisPoints % 100) ~/ 10;
    return tenth == 0 ? '$whole%' : '$whole.$tenth%';
  }

  @override
  List<Object?> get props => [id, label, amountMinor, shareBasisPoints];
}
