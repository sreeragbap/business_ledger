import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/models/calendar_day.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:business_ledger/features/reports/domain/models/report_range.dart';
import 'package:business_ledger/features/reports/domain/models/transaction_row.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyStats.fromMap', () {
    test('parses a full stats doc', () {
      final stats = DailyStats.fromMap('2026-10-14', {
        'date': '2026-10-14',
        'dateTs': Timestamp.fromDate(DateTime.utc(2026, 10, 14)),
        'incomeMinor': 1200,
        'expenseMinor': 300,
        'cashInMinor': 1000,
        'cashOutMinor': 300,
        'byCategory': const {
          'c1': {'in': 1200},
          'c2': {'out': 300},
        },
        'byProject': const {
          'p1': {'in': 200, 'out': 100},
        },
        'byType': const {
          'sale': {'in': 1200},
        },
        'updatedAt': Timestamp.now(),
      });
      expect(stats.date, '2026-10-14');
      expect(stats.incomeMinor, 1200);
      expect(stats.cashOutMinor, 300);
      expect(stats.byCategory['c1'], const InOut(inMinor: 1200));
      expect(stats.byCategory['c2'], const InOut(outMinor: 300));
      expect(stats.byProject['p1']!.net, 100);
      expect(stats.byType['sale']!.inMinor, 1200);
    });

    test('missing fields are zero; the doc id stands in for the date', () {
      final stats = DailyStats.fromMap('2026-10-15', const {'cashInMinor': 50});
      expect(stats.date, '2026-10-15');
      expect(stats.incomeMinor, 0);
      expect(stats.expenseMinor, 0);
      expect(stats.cashInMinor, 50);
      expect(stats.byCategory, isEmpty);
      expect(stats.byType, isEmpty);
    });

    test('negative deltas are kept as is', () {
      final stats = DailyStats.fromMap('2026-10-15', const {
        'incomeMinor': -500,
      });
      expect(stats.incomeMinor, -500);
    });

    test('rejects fractional money and malformed slices', () {
      expect(
        () => DailyStats.fromMap('2026-10-15', const {'incomeMinor': 1.5}),
        throwsFormatException,
      );
      expect(
        () => DailyStats.fromMap('2026-10-15', const {
          'byCategory': {'c1': 5},
        }),
        throwsFormatException,
      );
      expect(
        () => DailyStats.fromMap('bad-id', const {}),
        throwsFormatException,
      );
    });
  });

  group('ReportRange', () {
    final today = DateTime(2026, 10, 14); // a Wednesday

    String keys(ReportRange r) => '${r.fromKey}..${r.toKey}';

    test('presets', () {
      expect(
        keys(ReportRange.preset(DateRangePreset.today, today)),
        '2026-10-14..2026-10-14',
      );
      expect(
        keys(ReportRange.preset(DateRangePreset.thisWeek, today)),
        '2026-10-12..2026-10-18',
      );
      expect(
        keys(ReportRange.preset(DateRangePreset.thisMonth, today)),
        '2026-10-01..2026-10-31',
      );
      expect(
        keys(ReportRange.preset(DateRangePreset.lastMonth, today)),
        '2026-09-01..2026-09-30',
      );
      expect(
        keys(ReportRange.preset(DateRangePreset.thisYear, today)),
        '2026-01-01..2026-12-31',
      );
    });

    test('last month from January is December of the previous year', () {
      expect(
        keys(
          ReportRange.preset(DateRangePreset.lastMonth, DateTime(2027, 1, 5)),
        ),
        '2026-12-01..2026-12-31',
      );
    });

    test('custom orders its ends and labels them', () {
      final r = ReportRange.custom(
        DateTime(2026, 10, 20),
        DateTime(2026, 9, 28),
      );
      expect(keys(r), '2026-09-28..2026-10-20');
      expect(r.days, 23);
      expect(r.label, '28 Sep – 20 Oct 2026');
      expect(r.title, r.label);
      expect(r.contains('2026-10-01'), isTrue);
      expect(r.contains('2026-10-21'), isFalse);
    });

    test('labels', () {
      expect(
        ReportRange.preset(DateRangePreset.thisMonth, today).label,
        '1 – 31 Oct 2026',
      );
      expect(
        ReportRange.preset(DateRangePreset.today, today).label,
        '14 Oct 2026',
      );
    });

    test('CalendarDay week start is Monday', () {
      expect(
        CalendarDay.key(CalendarDay.weekStart(DateTime.utc(2026, 10, 18))),
        '2026-10-12',
      );
      expect(
        CalendarDay.key(CalendarDay.weekStart(DateTime.utc(2026, 10, 12))),
        '2026-10-12',
      );
    });
  });

  group('TransactionRow', () {
    final map = {
      'type': 'sale',
      'status': 'confirmed',
      'direction': 'in',
      'description': '',
      'partyName': 'Asha Traders',
      'date': '2026-10-01',
      'dueDate': '2026-10-10',
      'totalMinor': 5000,
      'outstandingMinor': 2000,
      'paymentStatus': 'partiallyPaid',
    };

    test('parses and derives title and overdue', () {
      final row = TransactionRow.fromMap('t1', map);
      expect(row.type, TransactionType.sale);
      expect(row.direction, Direction.inflow);
      expect(row.paymentStatus, PaymentStatus.partiallyPaid);
      expect(row.title, 'Asha Traders');
      expect(row.isOverdue('2026-10-11'), isTrue);
      expect(row.isOverdue('2026-10-10'), isFalse);
    });

    test('a settled or draft entry is never overdue', () {
      final settled = TransactionRow.fromMap('t1', {
        ...map,
        'outstandingMinor': 0,
      });
      expect(settled.isOverdue('2027-01-01'), isFalse);

      final draft = TransactionRow.fromMap('t2', const {
        'type': 'payment',
        'status': 'draft',
      });
      expect(draft.direction, isNull);
      expect(draft.paymentStatus, isNull);
      expect(draft.title, 'Payment');
      expect(draft.isOverdue('2027-01-01'), isFalse);
    });
  });
}
