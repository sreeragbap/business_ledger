import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/local_writer.dart';
import 'package:business_ledger/core/sync/profile_sync.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_queue.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/services/business_service.dart';
import 'package:business_ledger/features/reports/domain/services/reports_service.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/services/transaction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_fakes.dart';
import '../../support/fake_backend.dart';

class _Writer extends Mock implements LocalWriter {}

class _Queue extends Mock implements SyncQueue {}

class _Engine extends Mock implements SyncEngine {}

class _Rpc extends Mock implements RpcClient {}

/// The services' reads straight from the on-device store (drift SQL).
void main() {
  late LocalStore store;

  setUp(() async {
    store = memoryStore();
    await store.claimFor('u1');
  });

  tearDown(() => store.db.close());

  Map<String, dynamic> tx(
    String id, {
    String business = 'b1',
    String type = 'sale',
    String direction = 'in',
    String status = 'confirmed',
    String date = '2026-10-01',
    String? dueDate,
    int total = 1000,
    int outstanding = 0,
    String? paymentStatus,
    String? categoryId,
    String? partyId,
    List<String> tokens = const [],
    String? deletedAt,
  }) => {
    'id': id,
    'business_id': business,
    'type': type,
    'direction': direction,
    'status': status,
    'date': date,
    'due_date': dueDate,
    'total_minor': total,
    'outstanding_minor': outstanding,
    'payment_status': paymentStatus,
    'is_open': status == 'confirmed' && outstanding > 0,
    'category_id': categoryId,
    'party_id': partyId,
    'search_tokens': tokens,
    'created_at': '${date}T10:00:00+00:00',
    'deleted_at': deletedAt,
  };

  group('transactions', () {
    late TransactionService service;

    setUp(() async {
      service = TransactionService(
        store,
        _Writer(),
        FakeIdentity(),
        _Queue(),
        _Engine(),
      );
      await store.upsertRows(SyncTable.transactions, [
        tx(
          't1',
          dueDate: '2026-10-05',
          total: 5000,
          outstanding: 3000,
          paymentStatus: 'partiallyPaid',
          categoryId: 'c1',
          partyId: 'p1',
          tokens: ['ce', 'cem', 'cement', 'as', 'ash', 'asha'],
        ),
        tx(
          't2',
          date: '2026-10-03',
          type: 'expense',
          direction: 'out',
          total: 800,
          paymentStatus: 'paid',
          categoryId: 'c2',
          tokens: ['di', 'die', 'diesel'],
        ),
        tx('t3', date: '2026-10-02', status: 'draft', total: 200),
        tx('t4', business: 'b2', date: '2026-10-04'),
        tx(
          't5',
          date: '2026-10-04',
          status: 'draft',
          deletedAt: '2026-10-05T00:00:00+00:00',
        ),
        tx(
          't6',
          date: '2026-09-20',
          dueDate: '2026-10-30',
          total: 9000,
          outstanding: 9000,
          paymentStatus: 'unpaid',
          tokens: ['ce', 'cem', 'cement'],
        ),
      ]);
    });

    Future<List<String>> ids(
      TransactionFilter filter, {
      int limit = 50,
    }) async {
      final result = await service
          .watchTransactions(
            'b1',
            filter,
            limit: limit,
            today: '2026-10-10',
          )
          .first;
      return [for (final tx in result.dataOrNull!.items) tx.id];
    }

    test('newest first by default; other businesses and deleted drafts '
        'never show', () async {
      expect(await ids(const TransactionFilter()), ['t2', 't3', 't1', 't6']);
    });

    test('filters run in SQL: status, type, category, party, dates', () async {
      expect(
        await ids(const TransactionFilter(status: TransactionStatus.draft)),
        ['t3'],
      );
      expect(
        await ids(const TransactionFilter(type: TransactionType.expense)),
        ['t2'],
      );
      expect(await ids(const TransactionFilter(categoryId: 'c1')), ['t1']);
      expect(await ids(const TransactionFilter(partyId: 'p1')), ['t1']);
      expect(
        await ids(
          const TransactionFilter(from: '2026-10-01', to: '2026-10-02'),
        ),
        ['t3', 't1'],
      );
    });

    test('payment filters: stored status, outstanding and overdue', () async {
      expect(
        await ids(const TransactionFilter(payment: PaymentFilter.paid)),
        ['t2'],
      );
      expect(
        await ids(TransactionFilter.outstanding),
        ['t1', 't6'],
      );
      expect(
        await ids(const TransactionFilter(payment: PaymentFilter.overdue)),
        ['t1'],
        reason: 'only t1 was due before 2026-10-10',
      );
    });

    test('search: every word must be a stored token', () async {
      expect(await ids(const TransactionFilter(search: 'cem')), ['t1', 't6']);
      expect(await ids(const TransactionFilter(search: 'Cement asha')), [
        't1',
      ]);
      expect(await ids(const TransactionFilter(search: "o'neil")), isEmpty);
    });

    test('amount sorts and the window limit', () async {
      expect(
        await ids(const TransactionFilter(sort: TransactionSort.amountDesc)),
        ['t6', 't1', 't2', 't3'],
      );
      expect(
        await ids(
          const TransactionFilter(sort: TransactionSort.dateAsc),
          limit: 2,
        ),
        ['t6', 't1'],
      );
    });

    test('a page reports a full window as "has more"', () async {
      final page =
          (await service
                  .watchTransactions(
                    'b1',
                    const TransactionFilter(),
                    limit: 2,
                    today: '2026-10-10',
                  )
                  .first)
              .dataOrNull!;
      expect(page.hasMore, isTrue);
      expect(page.plan.deviceFilters, isEmpty);
    });

    test('linked refund entries and one transaction', () async {
      await store.upsertRows(SyncTable.transactions, [
        {
          ...tx('r1', type: 'refund', direction: 'out'),
          'linked_transaction_id': 't1',
        },
      ]);
      final linked = await service.watchLinked('b1', 't1').first;
      expect([for (final t in linked.dataOrNull!) t.id], ['r1']);
      final one = await service.watchTransaction('b1', 't1').first;
      expect(one.dataOrNull!.outstandingMinor, 3000);
    });
  });

  group('reports', () {
    late ReportsService service;

    setUp(() async {
      service = ReportsService(store, _Engine());
      await store.upsertRows(SyncTable.transactions, [
        tx('a', outstanding: 3000, total: 5000),
        tx('b', outstanding: 4500000000000, total: 9000000000000),
        tx('c', direction: 'out', type: 'purchase', outstanding: 700),
        tx('d', status: 'draft'),
        tx('e', business: 'b2', outstanding: 99),
      ]);
    });

    test(
      'receivables and payables are summed in SQLite, as integers',
      () async {
        final result = await service.receivablesAndPayables('b1');
        final balances = result.dataOrNull!;
        expect(balances.receivableMinor, 4500000003000);
        expect(balances.payableMinor, 700);
        expect(balances.fromCache, isFalse);
      },
    );

    test('nothing open sums to zero', () async {
      final result = await service.receivablesAndPayables('empty');
      expect(result.dataOrNull!.receivableMinor, 0);
      expect(result.dataOrNull!.payableMinor, 0);
    });

    test('daily stats in a range, oldest first', () async {
      await store.upsertRows(SyncTable.dailyStats, [
        for (final day in ['2026-10-03', '2026-10-01', '2026-09-30'])
          {
            'business_id': 'b1',
            'date': day,
            'income_minor': 100,
            'by_category': {
              'c1': {'in': 100, 'out': 0},
            },
          },
      ]);
      final result = await service
          .watchStats('b1', from: '2026-10-01', to: '2026-10-31')
          .first;
      final days = result.dataOrNull!;
      expect([for (final d in days) d.date], ['2026-10-01', '2026-10-03']);
      expect(days.first.byCategory['c1']!.inMinor, 100);
    });

    test('open transactions by due date, overdue only', () async {
      await store.upsertRows(SyncTable.transactions, [
        tx('f', outstanding: 10, dueDate: '2026-10-01'),
        tx('g', outstanding: 10, dueDate: '2026-12-01'),
      ]);
      final result = await service
          .openTransactions('b1', overdueOnly: true, today: '2026-11-01')
          .first;
      expect([for (final r in result.dataOrNull!) r.id], ['f']);
      final outs = await service
          .openTransactions('b1', direction: Direction.outflow)
          .first;
      expect([for (final r in outs.dataOrNull!) r.id], ['c']);
    });
  });

  group('businesses', () {
    late BusinessService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = BusinessService(
        store,
        _Rpc(),
        _Writer(),
        await SharedPreferences.getInstance(),
        ProfileSync(store, FakeRemoteTables()),
        _Engine(),
      );
    });

    test(
      "the user's businesses come from their memberships, by name",
      () async {
        await store.upsertRows(SyncTable.businesses, [
          {'id': 'b1', 'name': 'zeta'},
          {'id': 'b2', 'name': 'Alpha'},
          {'id': 'b3', 'name': 'Not mine'},
        ]);
        await store.upsertRows(SyncTable.members, [
          {'business_id': 'b1', 'user_id': 'u1', 'role': 'owner'},
          {'business_id': 'b2', 'user_id': 'u1', 'role': 'viewer'},
          {'business_id': 'b3', 'user_id': 'u2', 'role': 'owner'},
        ]);
        final result = await service.watchMyBusinesses('u1').first;
        expect([for (final b in result.dataOrNull!) b.name], ['Alpha', 'zeta']);
      },
    );

    test('a business not stored yet is "unknown", not "gone", until the '
        'first pull', () async {
      final seen = <AppResult<Business?>>[];
      final subscription = service.watchBusiness('b1').listen(seen.add);
      await pumpEventQueue();
      expect(seen, isEmpty);

      await store.markPulled();
      await pumpEventQueue();
      expect(seen.single.dataOrNull, isNull);

      await store.upsertRows(SyncTable.businesses, [
        {
          'id': 'b1',
          'name': 'Shop',
          'currency_code': 'INR',
          'currency_decimals': 2,
          'currency_symbol': '₹',
        },
      ]);
      await pumpEventQueue();
      expect(seen.last.dataOrNull!.name, 'Shop');
      await subscription.cancel();
    });
  });
}
