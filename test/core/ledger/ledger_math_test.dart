import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs `shared/ledger_cases.json`, the fixtures the Cloud Functions suite
/// runs too. A rule that changes on one side and not the other fails here.
void main() {
  final cases =
      jsonDecode(File('shared/ledger_cases.json').readAsStringSync())
          as Map<String, dynamic>;

  Balance balanceOf(Map<String, dynamic> start) => Balance(
    total: start['total'] as int,
    paid: (start['paid'] as int?) ?? 0,
    refunded: (start['refunded'] as int?) ?? 0,
    credited: (start['credited'] as int?) ?? 0,
  );

  TransactionStatus statusOf(Map<String, dynamic> start) =>
      TransactionStatus.fromKey(
        (start['transactionStatus'] as String?) ?? 'confirmed',
      );

  void expectEnd(
    Balance balance,
    Map<String, dynamic> end, {
    required bool settleable,
  }) {
    final checks = <String, int Function()>{
      'paid': () => balance.paid,
      'refunded': () => balance.refunded,
      'credited': () => balance.credited,
      'outstanding': () => balance.outstanding,
      'effective': () => balance.effective,
    };
    for (final entry in checks.entries) {
      if (end[entry.key] case final int expected) {
        expect(entry.value(), expected, reason: entry.key);
      }
    }
    if (end['status'] case final String status) {
      expect(
        LedgerMath.paymentStatusOf(balance, settleable: settleable).key,
        status,
      );
    }
  }

  group('settlements', () {
    for (final raw in cases['settlements'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        final start = c['start'] as Map<String, dynamic>;
        final settleable = (start['settleable'] as bool?) ?? true;
        var balance = balanceOf(start);

        for (final rawOp in c['ops'] as List<dynamic>) {
          final op = rawOp as Map<String, dynamic>;
          final kind = SettlementKind.fromKey(op['kind'] as String);
          final amount = op['amount'] as int;
          final violation = LedgerMath.checkSettlement(
            kind: kind,
            balance: balance,
            amount: amount,
            status: statusOf(start),
            settleable: settleable,
          );
          expect(violation?.name, op['violation']);
          if (violation == null) {
            balance = LedgerMath.apply(balance, kind, amount);
          }
        }
        expectEnd(
          balance,
          c['end'] as Map<String, dynamic>,
          settleable: settleable,
        );
      });
    }
  });

  group('total edits', () {
    for (final raw in cases['totalEdits'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        final balance = balanceOf(c['start'] as Map<String, dynamic>);
        final newTotal = c['newTotal'] as int;
        final violation = LedgerMath.checkTotalEdit(balance, newTotal);
        expect(violation?.name, c['violation']);
        if (c['end'] case final Map<String, dynamic> end) {
          expectEnd(
            balance.copyWith(total: newTotal),
            end,
            settleable: true,
          );
        }
      });
    }
  });

  group('cancels', () {
    for (final raw in cases['cancels'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        final start = c['start'] as Map<String, dynamic>;
        final violation = LedgerMath.checkCancel(
          balanceOf(start),
          statusOf(start),
        );
        expect(violation?.name, c['violation']);
      });
    }
  });

  group('overdue', () {
    for (final raw in cases['overdue'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['name'] as String, () {
        expect(
          LedgerMath.isOverdue(
            status: TransactionStatus.fromKey(c['status'] as String),
            outstanding: c['outstanding'] as int,
            dueDate: c['dueDate'] as String?,
            today: c['today'] as String,
          ),
          c['expect'],
        );
      });
    }
  });

  group('line amounts', () {
    for (final raw in cases['lineAmounts'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test('${c['quantityMilli']} × ${c['rateMinor']}', () {
        expect(
          Money.lineAmount(
            quantityMilli: c['quantityMilli'] as int,
            rateMinor: c['rateMinor'] as int,
          ),
          c['expect'],
        );
      });
    }
  });

  test('every refund keeps outstanding non-negative and amounts single', () {
    // Property check over a grid: no sequence the rules accept may
    // double count, go negative, or settle past the total.
    for (var total = 1; total <= 40; total += 13) {
      for (var pay = 0; pay <= total; pay += 7) {
        for (var refund = 0; refund <= pay; refund += 5) {
          var balance = Balance(total: total);
          for (final (kind, amount) in <(SettlementKind, int)>[
            (SettlementKind.payment, pay),
            (SettlementKind.refund, refund),
          ]) {
            if (amount == 0) continue;
            final violation = LedgerMath.checkSettlement(
              kind: kind,
              balance: balance,
              amount: amount,
              status: TransactionStatus.confirmed,
              settleable: true,
            );
            expect(violation, isNull);
            balance = LedgerMath.apply(balance, kind, amount);
          }
          expect(balance.outstanding, total - pay);
          expect(balance.effective, total - refund);
          expect(balance.netPaid + balance.outstanding, balance.effective);
        }
      }
    }
  });
}
