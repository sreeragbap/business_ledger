import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/search_tokens.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:equatable/equatable.dart';

/// Free-text search over `searchTokens` (lowercase word prefixes, see
/// `SearchTokens`).
abstract final class TransactionSearch {
  static final RegExp _separator = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  /// The query's words, lowercased and cut to the longest indexed prefix.
  static List<String> words(String query) => [
    for (final word in query.toLowerCase().split(_separator))
      if (word.isNotEmpty)
        word.length > SearchTokens.maxPrefixLength
            ? word.substring(0, SearchTokens.maxPrefixLength)
            : word,
  ];

  /// The one token Firestore filters on (`array-contains`): the last word,
  /// the one being typed. `null` for a blank query.
  static String? serverToken(String query) {
    final all = words(query);
    return all.isEmpty ? null : all.last;
  }

  /// Every word must be a stored prefix. Checked on the device, because
  /// Firestore allows one `array-contains` per query.
  static bool matches(LedgerTransaction tx, String query) {
    final all = words(query);
    if (all.isEmpty) return true;
    final tokens = tx.searchTokens.toSet();
    return all.every(tokens.contains);
  }
}

/// What the transactions list shows. Every part is applied on the device
/// (see [matches]); `TransactionQueryPlan` decides which parts Firestore can
/// apply first.
class TransactionFilter extends Equatable {
  const TransactionFilter({
    this.status,
    this.type,
    this.categoryId,
    this.projectId,
    this.partyId,
    this.payment,
    this.from,
    this.to,
    this.search = '',
    this.sort = TransactionSort.dateDesc,
  });

  /// Pending money: confirmed entries with something still outstanding.
  static const TransactionFilter outstanding = TransactionFilter(
    payment: PaymentFilter.open,
  );

  final TransactionStatus? status;
  final TransactionType? type;
  final String? categoryId;
  final String? projectId;
  final String? partyId;
  final PaymentFilter? payment;

  /// Inclusive `yyyy-MM-dd` bounds on the transaction date.
  final String? from;
  final String? to;
  final String search;
  final TransactionSort sort;

  bool get hasSearch => TransactionSearch.words(search).isNotEmpty;

  /// How many filters (not counting search and sort) are set.
  int get activeCount => [
    status,
    type,
    categoryId,
    projectId,
    partyId,
    payment,
    from ?? to,
  ].where((value) => value != null).length;

  bool get isFiltering => activeCount > 0 || hasSearch;

  bool matches(LedgerTransaction tx, String today) {
    if (status != null && tx.status != status) return false;
    if (type != null && tx.type != type) return false;
    if (categoryId != null && tx.categoryId != categoryId) return false;
    if (projectId != null && tx.projectId != projectId) return false;
    if (partyId != null && tx.partyId != partyId) return false;
    final date = tx.date;
    if (from != null && (date == null || date.compareTo(from!) < 0)) {
      return false;
    }
    if (to != null && (date == null || date.compareTo(to!) > 0)) return false;
    switch (payment) {
      case null:
        break;
      case PaymentFilter.open:
        if (!tx.isConfirmed || tx.outstandingMinor <= 0) return false;
      case PaymentFilter.overdue:
        if (!tx.isOverdue(today)) return false;
      case final PaymentFilter stored:
        if (tx.paymentStatus != stored.stored) return false;
    }
    return TransactionSearch.matches(tx, search);
  }

  /// Filters and orders [items] on the device. The sort is stable, and ties
  /// fall back to the newest first.
  List<LedgerTransaction> apply(
    Iterable<LedgerTransaction> items,
    String today,
  ) {
    final kept = items.where((tx) => matches(tx, today)).toList();
    int byDate(LedgerTransaction a, LedgerTransaction b) {
      final dates = (b.date ?? '').compareTo(a.date ?? '');
      if (dates != 0) return dates;
      final bCreated = b.createdAt?.millisecondsSinceEpoch ?? 1 << 52;
      final aCreated = a.createdAt?.millisecondsSinceEpoch ?? 1 << 52;
      return bCreated.compareTo(aCreated);
    }

    final indexed = kept.asMap().entries.toList()
      ..sort((x, y) {
        final a = x.value;
        final b = y.value;
        final order = switch (sort) {
          TransactionSort.dateDesc => byDate(a, b),
          TransactionSort.dateAsc => byDate(b, a),
          TransactionSort.amountDesc => b.totalMinor.compareTo(a.totalMinor),
          TransactionSort.amountAsc => a.totalMinor.compareTo(b.totalMinor),
        };
        if (order != 0) return order;
        final fallback = byDate(a, b);
        return fallback != 0 ? fallback : x.key.compareTo(y.key);
      });
    return [for (final entry in indexed) entry.value];
  }

  /// Nullable fields take a getter so they can be cleared.
  TransactionFilter copyWith({
    TransactionStatus? Function()? status,
    TransactionType? Function()? type,
    String? Function()? categoryId,
    String? Function()? projectId,
    String? Function()? partyId,
    PaymentFilter? Function()? payment,
    String? Function()? from,
    String? Function()? to,
    String? search,
    TransactionSort? sort,
  }) => TransactionFilter(
    status: status == null ? this.status : status(),
    type: type == null ? this.type : type(),
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    projectId: projectId == null ? this.projectId : projectId(),
    partyId: partyId == null ? this.partyId : partyId(),
    payment: payment == null ? this.payment : payment(),
    from: from == null ? this.from : from(),
    to: to == null ? this.to : to(),
    search: search ?? this.search,
    sort: sort ?? this.sort,
  );

  /// Everything cleared except the search text and the sort.
  TransactionFilter cleared() => TransactionFilter(search: search, sort: sort);

  @override
  List<Object?> get props => [
    status,
    type,
    categoryId,
    projectId,
    partyId,
    payment,
    from,
    to,
    search,
    sort,
  ];
}
