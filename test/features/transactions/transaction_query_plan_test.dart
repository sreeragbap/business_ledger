import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_query_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transaction_fixtures.dart';

TransactionQueryPlan plan(TransactionFilter filter) =>
    TransactionQueryPlan.of(filter, today: today);

/// Every server shape must be one `firestore.indexes.json` declares.
void expectIndexed(TransactionQueryPlan plan) {
  if (plan.openOnly) {
    expect(plan.equals, isEmpty);
    expect(plan.searchToken, isNull);
    expect(plan.orderBy, TransactionQueryPlan.dueField);
    return;
  }
  final fields = {
    ...plan.equals.keys,
    if (plan.searchToken != null) 'searchTokens',
  };
  expect(
    TransactionQueryPlan.indexedCombos.any(
      (combo) => combo.length == fields.length && combo.containsAll(fields),
    ),
    isTrue,
    reason: 'no index for $fields',
  );
  expect(plan.orderBy, TransactionQueryPlan.dateField);
  if (fields.isNotEmpty) {
    expect(plan.descending, isTrue, reason: 'composite indexes are desc');
  }
}

void main() {
  group('search token', () {
    test('is the last word, lowercased', () {
      expect(TransactionSearch.serverToken('Asha TRAD'), 'trad');
      expect(TransactionSearch.serverToken('  cement, '), 'cement');
      expect(TransactionSearch.serverToken('   '), isNull);
    });

    test('is cut to the longest indexed prefix', () {
      expect(
        TransactionSearch.serverToken('Supercalifragilistic'),
        'supercalifragil',
      );
      expect(TransactionSearch.words('a-b c'), ['a', 'b', 'c']);
    });
  });

  group('query plan', () {
    test('no filter: newest first, exact', () {
      final p = plan(const TransactionFilter());
      expectIndexed(p);
      expect(p.equals, isEmpty);
      expect(p.descending, isTrue);
      expect(p.exactOrder, isTrue);
      expect(p.deviceFilters, isEmpty);
    });

    test('oldest first uses the single-field index only when unfiltered', () {
      final plain = plan(
        const TransactionFilter(
          sort: TransactionSort.dateAsc,
          from: '2026-10-01',
        ),
      );
      expect(plain.descending, isFalse);
      expect(plain.exactOrder, isTrue);
      expect(plain.from, '2026-10-01');

      final filtered = plan(
        const TransactionFilter(
          sort: TransactionSort.dateAsc,
          type: TransactionType.sale,
        ),
      );
      expectIndexed(filtered);
      expect(filtered.descending, isTrue);
      expect(filtered.exactOrder, isFalse, reason: 'sorted on device');
    });

    test('status + type is one composite index', () {
      final p = plan(
        const TransactionFilter(
          status: TransactionStatus.confirmed,
          type: TransactionType.sale,
        ),
      );
      expectIndexed(p);
      expect(p.equals, {'status': 'confirmed', 'type': 'sale'});
      expect(p.deviceFilters, isEmpty);
    });

    test('type + category: the more selective goes to the server', () {
      final p = plan(
        const TransactionFilter(type: TransactionType.sale, categoryId: 'c1'),
      );
      expectIndexed(p);
      expect(p.equals, {'categoryId': 'c1'});
      expect(p.deviceFilters, {'type'});
    });

    test('party beats status, the rest is on the device', () {
      final p = plan(
        const TransactionFilter(
          status: TransactionStatus.confirmed,
          partyId: 'p1',
          projectId: 'pr1',
          payment: PaymentFilter.paid,
        ),
      );
      expectIndexed(p);
      expect(p.equals, {'partyId': 'p1'});
      expect(p.deviceFilters, {'status', 'projectId', 'payment'});
    });

    test('status + stored payment status', () {
      final p = plan(
        const TransactionFilter(
          status: TransactionStatus.confirmed,
          payment: PaymentFilter.partiallyPaid,
        ),
      );
      expectIndexed(p);
      expect(p.equals, {
        'status': 'confirmed',
        'paymentStatus': 'partiallyPaid',
      });
    });

    test('search: array-contains on the last word, others on device', () {
      final p = plan(
        const TransactionFilter(
          search: 'asha cem',
          status: TransactionStatus.confirmed,
          type: TransactionType.sale,
        ),
      );
      expectIndexed(p);
      expect(p.searchToken, 'cem');
      expect(p.equals, {'status': 'confirmed'});
      expect(p.deviceFilters, {'type', 'search'});
    });

    test('overdue: isOpen + dueDate < today, by due date', () {
      final p = plan(
        const TransactionFilter(
          payment: PaymentFilter.overdue,
          partyId: 'p1',
          from: '2026-01-01',
        ),
      );
      expectIndexed(p);
      expect(p.openOnly, isTrue);
      expect(p.dueBefore, today);
      expect(p.descending, isFalse);
      expect(p.exactOrder, isFalse);
      expect(p.deviceFilters, {'partyId', 'date'});
    });

    test('outstanding: isOpen only', () {
      final p = plan(TransactionFilter.outstanding);
      expect(p.openOnly, isTrue);
      expect(p.dueBefore, isNull);
    });

    test('overdue with a search uses the search index instead', () {
      final p = plan(
        const TransactionFilter(payment: PaymentFilter.overdue, search: 'asha'),
      );
      expectIndexed(p);
      expect(p.openOnly, isFalse);
      expect(p.searchToken, 'asha');
      expect(p.deviceFilters, {'overdue'});
    });

    test('amount sort is never exact', () {
      final p = plan(const TransactionFilter(sort: TransactionSort.amountAsc));
      expect(p.exactOrder, isFalse);
      expect(p.descending, isTrue);
    });
  });
}
