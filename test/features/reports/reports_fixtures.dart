import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';

final DateTime now = DateTime(2026, 10, 14, 10);

final List<DailyStats> octoberDays = [
  const DailyStats(
    date: '2026-10-01',
    incomeMinor: 100000,
    expenseMinor: 30000,
    cashInMinor: 60000,
    cashOutMinor: 30000,
    byCategory: {
      'c1': InOut(inMinor: 100000),
      'c2': InOut(outMinor: 30000),
    },
    byProject: {'p1': InOut(inMinor: 40000)},
  ),
  const DailyStats(
    date: '2026-10-09',
    incomeMinor: 20000,
    cashInMinor: 20000,
    byCategory: {'c1': InOut(inMinor: 20000)},
  ),
];

const TransactionRow overdueSale = TransactionRow(
  id: 't1',
  type: TransactionType.sale,
  status: TransactionStatus.confirmed,
  direction: Direction.inflow,
  dueDate: '2026-10-10',
  totalMinor: 50000,
  outstandingMinor: 50000,
  paymentStatus: PaymentStatus.unpaid,
);

const TransactionRow upcomingBill = TransactionRow(
  id: 't2',
  type: TransactionType.purchase,
  status: TransactionStatus.confirmed,
  direction: Direction.outflow,
  dueDate: '2026-10-20',
  totalMinor: 12000,
  outstandingMinor: 12000,
  paymentStatus: PaymentStatus.unpaid,
);
