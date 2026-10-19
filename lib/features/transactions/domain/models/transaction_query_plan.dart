import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:equatable/equatable.dart';

/// Which part of a [TransactionFilter] a backend query applies. Reads now
/// come from the on-device SQLite store, which applies the whole filter
/// ([local]); [TransactionQueryPlan.of] is the planner written for
/// Firestore's composite indexes, kept for a server-side search.
///
/// Whatever a plan leaves out is applied on the device
/// (`TransactionFilter.apply`), over the entries loaded so far.
///
/// Indexed shapes used (all `dateTs` descending unless noted):
/// `{}` (single-field `dateTs`), `status`, `type`, `categoryId`,
/// `projectId`, `partyId`, `paymentStatus`, `status+type`,
/// `status+categoryId`, `status+projectId`, `status+paymentStatus`,
/// `searchTokens(array-contains)`, `searchTokens+status`, and
/// `isOpen+dueDate` (ascending) for outstanding / overdue.
class TransactionQueryPlan extends Equatable {
  const TransactionQueryPlan({
    this.equals = const {},
    this.searchToken,
    this.openOnly = false,
    this.dueBefore,
    this.orderBy = dateField,
    this.descending = true,
    this.from,
    this.to,
    this.exactOrder = true,
    this.deviceFilters = const {},
  });

  factory TransactionQueryPlan.of(
    TransactionFilter filter, {
    required String today,
  }) {
    final token = TransactionSearch.serverToken(filter.search);
    final payment = filter.payment;
    final derivedPayment = payment != null && payment.isDerived;
    final multiWordSearch = TransactionSearch.words(filter.search).length > 1;

    // Outstanding / overdue without a search: `isOpen` + `dueDate` index.
    if (derivedPayment && token == null) {
      return TransactionQueryPlan(
        openOnly: true,
        dueBefore: payment == PaymentFilter.overdue ? today : null,
        orderBy: dueField,
        descending: false,
        exactOrder: false,
        deviceFilters: {
          if (filter.status != null) 'status',
          if (filter.type != null) 'type',
          if (filter.categoryId != null) 'categoryId',
          if (filter.projectId != null) 'projectId',
          if (filter.partyId != null) 'partyId',
          if (filter.from != null || filter.to != null) 'date',
        },
      );
    }

    final requested = <String, String>{
      'searchTokens': ?token,
      'status': ?filter.status?.key,
      'type': ?filter.type?.key,
      'categoryId': ?filter.categoryId,
      'projectId': ?filter.projectId,
      'partyId': ?filter.partyId,
      'paymentStatus': ?payment?.stored?.key,
    };

    var best = const <String>{};
    var bestScore = 0;
    for (final combo in indexedCombos) {
      if (!requested.keys.toSet().containsAll(combo)) continue;
      final score = combo.fold(0, (sum, field) => sum + _weights[field]!);
      if (score > bestScore) {
        best = combo;
        bestScore = score;
      }
    }

    final server = best.where((field) => field != 'searchTokens');
    final ascending = filter.sort == TransactionSort.dateAsc;
    // Ascending `dateTs` has only the single-field index.
    final canAscend = best.isEmpty;
    final descending = !(ascending && canAscend);
    final exactOrder = filter.sort.byDate && (descending != ascending);

    return TransactionQueryPlan(
      equals: {for (final field in server) field: requested[field]!},
      searchToken: best.contains('searchTokens') ? token : null,
      descending: descending,
      from: filter.from,
      to: filter.to,
      exactOrder: exactOrder,
      deviceFilters: {
        for (final field in requested.keys)
          if (!best.contains(field)) _filterName(field),
        if (derivedPayment) payment.name,
        if (multiWordSearch) 'search',
      },
    );
  }

  /// Everything applied by the query, in the order asked for: what the
  /// local store does.
  static const TransactionQueryPlan local = TransactionQueryPlan();

  static const String dateField = 'dateTs';
  static const String dueField = 'dueDate';

  /// Equality filters Firestore can combine with an `orderBy dateTs`, by
  /// field. Order matters only for ties.
  static const List<Set<String>> indexedCombos = [
    {},
    {'status'},
    {'type'},
    {'categoryId'},
    {'projectId'},
    {'partyId'},
    {'paymentStatus'},
    {'status', 'type'},
    {'status', 'categoryId'},
    {'status', 'projectId'},
    {'status', 'paymentStatus'},
    {'searchTokens'},
    {'searchTokens', 'status'},
  ];

  /// How much each server-side filter narrows the read. A search token or a
  /// party is far more selective than a status.
  static const Map<String, int> _weights = {
    'searchTokens': 100,
    'partyId': 50,
    'categoryId': 40,
    'projectId': 40,
    'paymentStatus': 30,
    'type': 20,
    'status': 10,
  };

  /// `{field: value}` equality filters for Firestore (not `searchTokens`).
  final Map<String, String> equals;

  /// `searchTokens array-contains` value.
  final String? searchToken;

  /// `isOpen == true`, ordered by `dueDate`.
  final bool openOnly;

  /// `dueDate < dueBefore` (overdue).
  final String? dueBefore;
  final String orderBy;
  final bool descending;

  /// `dateTs` range, applied server-side only when ordering by `dateTs`.
  final String? from;
  final String? to;

  /// Whether Firestore returns the entries in the order asked for. When not,
  /// the device sorts what has been loaded.
  final bool exactOrder;

  /// Filter names applied only on the device (for the UI and the report).
  final Set<String> deviceFilters;

  static String _filterName(String field) => switch (field) {
    'searchTokens' => 'search',
    'paymentStatus' => 'payment',
    _ => field,
  };

  @override
  List<Object?> get props => [
    equals,
    searchToken,
    openOnly,
    dueBefore,
    orderBy,
    descending,
    from,
    to,
    exactOrder,
    deviceFilters,
  ];

  @override
  String toString() =>
      'TransactionQueryPlan(equals: $equals, token: $searchToken, '
      'open: $openOnly, dueBefore: $dueBefore, orderBy: $orderBy '
      '${descending ? 'desc' : 'asc'}, range: $from..$to, '
      'exactOrder: $exactOrder, device: $deviceFilters)';
}

/// One live window of the list.
class TransactionPage extends Equatable {
  const TransactionPage({
    required this.items,
    required this.fetched,
    required this.limit,
    required this.plan,
  });

  /// After device filtering and sorting.
  final List<LedgerTransaction> items;

  /// Documents Firestore returned, before device filtering.
  final int fetched;
  final int limit;
  final TransactionQueryPlan plan;

  /// A full window suggests there is more to load.
  bool get hasMore => fetched >= limit;

  @override
  List<Object?> get props => [items, fetched, limit, plan];
}
