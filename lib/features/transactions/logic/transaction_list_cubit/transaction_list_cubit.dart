import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/repository/category_repository.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/domain/repository/party_repository.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/domain/repository/project_repository.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_query_plan.dart';
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'transaction_list_state.dart';

/// The transactions list: a live, filtered window that grows a page at a
/// time, with debounced search. Categories, parties and projects are
/// watched alongside for the filter sheets and chip labels.
@injectable
class TransactionListCubit extends Cubit<TransactionListState> {
  TransactionListCubit(
    this._repository,
    this._categories,
    this._parties,
    this._projects, {
    @ignoreParam Duration? debounce,
    @ignoreParam DateTime Function()? now,
  }) : _debounce = debounce ?? const Duration(milliseconds: 300),
       _now = now ?? DateTime.now,
       super(const TransactionListState());

  final TransactionRepository _repository;
  final CategoryRepository _categories;
  final PartyRepository _parties;
  final ProjectRepository _projects;
  final Duration _debounce;
  final DateTime Function() _now;

  static const int pageSize = 25;

  /// A ceiling on one live window. Past it, narrow the filter.
  static const int maxLimit = 500;

  StreamSubscription<AppResult<TransactionPage>>? _page;
  final List<StreamSubscription<Object?>> _lookups = [];
  Timer? _searchTimer;
  Completer<void>? _refreshed;

  /// Starts (or restarts, after a business switch) the list.
  Future<void> start(
    String businessId, {
    TransactionFilter filter = const TransactionFilter(),
  }) async {
    await _cancelAll();
    emit(
      TransactionListState(
        businessId: businessId,
        filter: filter,
        searchText: filter.search,
        loadStatus: const Status.loading(),
        today: LedgerDates.today(_now()),
      ),
    );
    _lookups
      ..add(
        _repository.watchQueued(businessId).listen((entries) {
          if (!isClosed) {
            emit(state.copyWith(syncMarks: SyncMark.byTransaction(entries)));
          }
        }),
      )
      ..add(
        _categories.watchCategories(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(categories: data));
          }
        }),
      )
      ..add(
        _parties.watchParties(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(parties: data));
          }
        }),
      )
      ..add(
        _projects.watchProjects(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(projects: data));
          }
        }),
      );
    await _subscribe();
  }

  Future<void> _subscribe() async {
    final businessId = state.businessId;
    if (businessId == null) return;
    await _page?.cancel();
    final today = LedgerDates.today(_now());
    if (today != state.today) emit(state.copyWith(today: today));
    _page = _repository
        .watchTransactions(
          businessId,
          state.filter,
          limit: state.limit,
          today: today,
        )
        .listen(_onPage);
  }

  void _onPage(AppResult<TransactionPage> result) {
    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            items: page.items,
            hasMore: page.hasMore,
            exactOrder: page.plan.exactOrder,
            deviceFilters: page.plan.deviceFilters,
            loadStatus: const Status.success(),
            loadingMore: false,
          ),
        );
        _completeRefresh();
        // Filters applied on the device can leave a short page while more
        // is waiting on the server: fetch on until the page is filled.
        if (page.items.length < pageSize &&
            page.hasMore &&
            page.plan.deviceFilters.isNotEmpty) {
          unawaited(loadMore());
        }
      case Failure(:final error):
        emit(
          state.copyWith(
            loadStatus: Status.fromException(error),
            loadingMore: false,
          ),
        );
        _completeRefresh();
    }
  }

  void _completeRefresh() {
    final completer = _refreshed;
    _refreshed = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  /// Updates the field at once and the query after a pause in typing.
  void search(String text) {
    emit(state.copyWith(searchText: text));
    _searchTimer?.cancel();
    _searchTimer = Timer(
      _debounce,
      () => unawaited(applyFilter(state.filter.copyWith(search: text))),
    );
  }

  /// Replaces the filter and reloads from the first page.
  Future<void> applyFilter(TransactionFilter filter) async {
    if (filter == state.filter || state.businessId == null) return;
    emit(
      state.copyWith(
        filter: filter,
        searchText: filter.search,
        limit: pageSize,
        loadStatus: const Status.loading(),
      ),
    );
    await _subscribe();
  }

  Future<void> updateFilter(
    TransactionFilter Function(TransactionFilter filter) change,
  ) => applyFilter(change(state.filter));

  Future<void> clearFilters() => applyFilter(state.filter.cleared());

  Future<void> setSort(TransactionSort sort) =>
      applyFilter(state.filter.copyWith(sort: sort));

  /// Grows the live window by a page.
  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.limit >= maxLimit ||
        state.businessId == null) {
      return;
    }
    emit(state.copyWith(limit: state.limit + pageSize, loadingMore: true));
    await _subscribe();
  }

  /// Pulls what changed on the server, then re-attaches the listener;
  /// completes when the next result arrives.
  Future<void> refresh() async {
    await _repository.refresh();
    if (isClosed) return;
    final completer = _refreshed = Completer<void>();
    await _subscribe();
    return completer.future;
  }

  Future<void> _cancelAll() async {
    _searchTimer?.cancel();
    await _page?.cancel();
    _page = null;
    for (final subscription in _lookups) {
      await subscription.cancel();
    }
    _lookups.clear();
  }

  @override
  Future<void> close() async {
    await _cancelAll();
    _completeRefresh();
    return super.close();
  }
}
