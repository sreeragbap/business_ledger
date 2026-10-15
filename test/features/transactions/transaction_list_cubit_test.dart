import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/logic/transaction_list_cubit/transaction_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_business_repositories.dart';
import 'stub_transaction_repository.dart';
import 'transaction_fixtures.dart';

void main() {
  late StubTransactionRepository repository;
  late StubCategoryRepository categoryRepository;
  late StubPartyRepository parties;
  late StubProjectRepository projects;

  setUp(() {
    repository = StubTransactionRepository();
    categoryRepository = StubCategoryRepository();
    parties = StubPartyRepository();
    projects = StubProjectRepository();
  });

  tearDown(() async {
    await repository.dispose();
    await categoryRepository.dispose();
    await parties.dispose();
    await projects.dispose();
  });

  TransactionListCubit build({Duration debounce = Duration.zero}) =>
      TransactionListCubit(
        repository,
        categoryRepository,
        parties,
        projects,
        debounce: debounce,
        now: () => now,
      );

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  List<LedgerTransaction> many(int count) => [
    for (var i = 0; i < count; i++) confirmedSale(id: 't$i'),
  ];

  test('starts with the first page for today', () async {
    final cubit = build();
    await cubit.start('b1');
    expect(cubit.state.loadStatus.isLoading, isTrue);
    expect(repository.watchCalls.single.limit, TransactionListCubit.pageSize);
    expect(repository.watchCalls.single.today, today);

    repository.emitPage([confirmedSale(), draftExpense()]);
    await flush();
    expect(cubit.state.items, hasLength(2));
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.loadStatus.isSuccess, isTrue);
    expect(cubit.state.sections.map((s) => s.label), [
      'Monday, 5 October 2026',
      'Thursday, 1 October 2026',
    ]);
    await cubit.close();
  });

  test('loadMore grows the window by a page', () async {
    final cubit = build();
    await cubit.start('b1');
    repository.emitPage(many(TransactionListCubit.pageSize));
    await flush();
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();
    expect(repository.watchCalls.last.limit, TransactionListCubit.pageSize * 2);
    expect(cubit.state.loadingMore, isTrue);
    // A second call while loading is ignored.
    await cubit.loadMore();
    expect(repository.watchCalls, hasLength(2));

    repository.emitPage(many(30));
    await flush();
    expect(cubit.state.loadingMore, isFalse);
    expect(cubit.state.hasMore, isFalse);
    expect(cubit.state.items, hasLength(30));
    await cubit.close();
  });

  test('a short page filtered on the device fetches on by itself', () async {
    final cubit = build();
    await cubit.start(
      'b1',
      filter: const TransactionFilter(
        status: TransactionStatus.confirmed,
        type: TransactionType.sale,
        partyId: 'nobody',
      ),
    );
    // Full window from the server, but the device filter keeps none.
    repository.emitPage(many(TransactionListCubit.pageSize));
    await flush();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.deviceFilters, isNotEmpty);
    expect(repository.watchCalls.last.limit, TransactionListCubit.pageSize * 2);
    await cubit.close();
  });

  test('search is debounced and resets paging', () async {
    final cubit = build(debounce: const Duration(milliseconds: 20));
    await cubit.start('b1');
    repository.emitPage(many(TransactionListCubit.pageSize));
    await flush();
    await cubit.loadMore();

    cubit
      ..search('as')
      ..search('ash')
      ..search('asha');
    expect(cubit.state.searchText, 'asha');
    expect(cubit.state.filter.search, '', reason: 'not yet');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(cubit.state.filter.search, 'asha');
    expect(repository.watchCalls.last.filter.search, 'asha');
    expect(repository.watchCalls.last.limit, TransactionListCubit.pageSize);
    // Three keystrokes, one query.
    expect(
      repository.watchCalls.where((c) => c.filter.search.isNotEmpty),
      hasLength(1),
    );
    await cubit.close();
  });

  blocTest<TransactionListCubit, TransactionListState>(
    'filters apply on the device too (overdue derived from today)',
    build: build,
    act: (cubit) async {
      await cubit.start('b1');
      await cubit.updateFilter(
        (f) => f.copyWith(payment: () => PaymentFilter.overdue),
      );
      repository.emitPage([
        confirmedSale(id: 'late', dueDate: '2026-10-01'),
        confirmedSale(id: 'later', dueDate: '2026-12-01'),
      ]);
      await flush();
    },
    verify: (cubit) {
      expect(cubit.state.items!.map((t) => t.id), ['late']);
      expect(cubit.state.exactOrder, isFalse);
      expect(repository.watchCalls.last.filter.payment, PaymentFilter.overdue);
    },
  );

  test('clearFilters keeps search and sort', () async {
    final cubit = build();
    await cubit.start(
      'b1',
      filter: const TransactionFilter(
        type: TransactionType.sale,
        search: 'asha',
        sort: TransactionSort.amountDesc,
      ),
    );
    await cubit.clearFilters();
    expect(
      cubit.state.filter,
      const TransactionFilter(
        search: 'asha',
        sort: TransactionSort.amountDesc,
      ),
    );
    await cubit.close();
  });

  test('a failed refresh keeps the list and reports the error', () async {
    final cubit = build();
    await cubit.start('b1');
    repository.emitPage([confirmedSale()]);
    await flush();
    final refreshed = cubit.refresh();
    await flush();
    repository.pages.add(const Failure(AppException.offline()));
    await refreshed;
    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.loadStatus.isFailure, isTrue);
    await cubit.close();
  });

  test('quick add picks the most recently created type', () async {
    final cubit = build();
    await cubit.start('b1');
    repository.emitPage([confirmedSale(), draftExpense()]);
    await flush();
    expect(cubit.state.recentType, TransactionType.expense);
    await cubit.close();
  });

  test('lookups resolve chip labels', () async {
    final cubit = build();
    await cubit.start('b1');
    categoryRepository.categories.add(const Success(categories));
    await flush();
    expect(cubit.state.categoryName('c-rent'), 'Rent');
    await cubit.close();
  });

  test('sort change re-queries', () async {
    final cubit = build();
    await cubit.start('b1');
    await cubit.setSort(TransactionSort.dateAsc);
    expect(repository.watchCalls.last.filter.sort, TransactionSort.dateAsc);
    unawaited(cubit.close());
  });
}
