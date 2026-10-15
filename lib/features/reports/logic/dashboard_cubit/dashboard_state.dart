part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  const DashboardState({
    required this.range,
    required this.today,
    this.businessId,
    this.currency = Currency.inr,
    this.totals = StatsTotals.zero,
    this.series = const [],
    this.balances,
    this.pending = const [],
    this.recent = const [],
    this.statsStatus = const Status.initial(),
    this.balancesStatus = const Status.initial(),
    this.pendingStatus = const Status.initial(),
    this.recentStatus = const Status.initial(),
  });

  factory DashboardState.initial([DateTime? now]) {
    final today = CalendarDay.today(now);
    return DashboardState(
      range: ReportRange.preset(DateRangePreset.thisMonth, today),
      today: CalendarDay.key(today),
    );
  }

  final String? businessId;
  final Currency currency;
  final ReportRange range;

  /// `yyyy-MM-dd`, for overdue checks.
  final String today;
  final StatsTotals totals;
  final List<StatsBucket> series;

  /// `null` until first loaded.
  final ReceivablesPayables? balances;

  /// Open transactions by due date, both directions.
  final List<TransactionRow> pending;
  final List<TransactionRow> recent;

  final Status statsStatus;
  final Status balancesStatus;
  final Status pendingStatus;
  final Status recentStatus;

  List<TransactionRow> get overdue => [
    for (final row in pending)
      if (row.isOverdue(today)) row,
  ];

  /// First load still running: show skeletons rather than zeros.
  bool get isLoadingFirst => statsStatus.isLoading && totals.days == 0;

  DashboardState copyWith({
    String? businessId,
    Currency? currency,
    ReportRange? range,
    String? today,
    StatsTotals? totals,
    List<StatsBucket>? series,
    ReceivablesPayables? balances,
    List<TransactionRow>? pending,
    List<TransactionRow>? recent,
    Status? statsStatus,
    Status? balancesStatus,
    Status? pendingStatus,
    Status? recentStatus,
  }) => DashboardState(
    businessId: businessId ?? this.businessId,
    currency: currency ?? this.currency,
    range: range ?? this.range,
    today: today ?? this.today,
    totals: totals ?? this.totals,
    series: series ?? this.series,
    balances: balances ?? this.balances,
    pending: pending ?? this.pending,
    recent: recent ?? this.recent,
    statsStatus: statsStatus ?? this.statsStatus,
    balancesStatus: balancesStatus ?? this.balancesStatus,
    pendingStatus: pendingStatus ?? this.pendingStatus,
    recentStatus: recentStatus ?? this.recentStatus,
  );

  @override
  List<Object?> get props => [
    businessId,
    currency,
    range,
    today,
    totals,
    series,
    balances,
    pending,
    recent,
    statsStatus,
    balancesStatus,
    pendingStatus,
    recentStatus,
  ];
}
