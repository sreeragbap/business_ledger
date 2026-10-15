part of 'transaction_list_cubit.dart';

/// A run of entries under one date heading.
class TransactionSection extends Equatable {
  const TransactionSection({required this.label, required this.items});

  final String label;
  final List<LedgerTransaction> items;

  @override
  List<Object?> get props => [label, items];
}

class TransactionListState extends Equatable {
  const TransactionListState({
    this.businessId,
    this.filter = const TransactionFilter(),
    this.searchText = '',
    this.items,
    this.limit = TransactionListCubit.pageSize,
    this.hasMore = false,
    this.exactOrder = true,
    this.deviceFilters = const {},
    this.loadStatus = const Status.initial(),
    this.loadingMore = false,
    this.categories = const [],
    this.parties = const [],
    this.projects = const [],
    this.today = '',
  });

  final String? businessId;
  final TransactionFilter filter;

  /// What is in the search field (the filter follows after a debounce).
  final String searchText;

  /// Filtered and sorted. `null` until the first result.
  final List<LedgerTransaction>? items;
  final int limit;
  final bool hasMore;

  /// Whether the server returned the requested order. When not, the order
  /// covers only the entries loaded so far.
  final bool exactOrder;

  /// Parts of the filter applied on the device.
  final Set<String> deviceFilters;
  final Status loadStatus;
  final bool loadingMore;
  final List<Category> categories;
  final List<Party> parties;
  final List<Project> projects;

  /// `yyyy-MM-dd`, for overdue.
  final String today;

  /// Entries under date headings, newest or oldest first as sorted. An
  /// amount sort has no date grouping.
  List<TransactionSection> get sections {
    final list = items;
    if (list == null || list.isEmpty) return const [];
    if (!filter.sort.byDate) {
      return [TransactionSection(label: filter.sort.label, items: list)];
    }
    final sections = <TransactionSection>[];
    String? currentLabel;
    var current = <LedgerTransaction>[];
    for (final tx in list) {
      final label = LedgerDates.sectionLabel(tx.date, today);
      if (label != currentLabel) {
        if (currentLabel != null) {
          sections.add(TransactionSection(label: currentLabel, items: current));
        }
        currentLabel = label;
        current = [];
      }
      current.add(tx);
    }
    sections.add(TransactionSection(label: currentLabel!, items: current));
    return sections;
  }

  /// The type of the most recently created entry, for quick add.
  TransactionType get recentType {
    LedgerTransaction? newest;
    for (final tx in items ?? const <LedgerTransaction>[]) {
      if (!tx.type.isCreatable) continue;
      final created = tx.createdAt;
      if (created == null) continue;
      if (newest == null || created.isAfter(newest.createdAt!)) newest = tx;
    }
    return newest?.type ?? TransactionType.expense;
  }

  String? categoryName(String? id) =>
      categories.where((c) => c.id == id).firstOrNull?.name;
  String? partyName(String? id) =>
      parties.where((p) => p.id == id).firstOrNull?.name;
  String? projectName(String? id) =>
      projects.where((p) => p.id == id).firstOrNull?.displayName;

  TransactionListState copyWith({
    TransactionFilter? filter,
    String? searchText,
    List<LedgerTransaction>? items,
    int? limit,
    bool? hasMore,
    bool? exactOrder,
    Set<String>? deviceFilters,
    Status? loadStatus,
    bool? loadingMore,
    List<Category>? categories,
    List<Party>? parties,
    List<Project>? projects,
    String? today,
  }) => TransactionListState(
    businessId: businessId,
    filter: filter ?? this.filter,
    searchText: searchText ?? this.searchText,
    items: items ?? this.items,
    limit: limit ?? this.limit,
    hasMore: hasMore ?? this.hasMore,
    exactOrder: exactOrder ?? this.exactOrder,
    deviceFilters: deviceFilters ?? this.deviceFilters,
    loadStatus: loadStatus ?? this.loadStatus,
    loadingMore: loadingMore ?? this.loadingMore,
    categories: categories ?? this.categories,
    parties: parties ?? this.parties,
    projects: projects ?? this.projects,
    today: today ?? this.today,
  );

  @override
  List<Object?> get props => [
    businessId,
    filter,
    searchText,
    items,
    limit,
    hasMore,
    exactOrder,
    deviceFilters,
    loadStatus,
    loadingMore,
    categories,
    parties,
    projects,
    today,
  ];
}
