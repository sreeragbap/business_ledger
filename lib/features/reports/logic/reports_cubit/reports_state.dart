part of 'reports_cubit.dart';

class ReportsState extends Equatable {
  const ReportsState({
    required this.range,
    required this.granularity,
    this.businessId,
    this.currency = Currency.inr,
    this.scope,
    this.labels = ReportLabels.empty,
    this.days = const [],
    this.totals = StatsTotals.zero,
    this.series = const [],
    this.incomeByCategory = const [],
    this.expenseByCategory = const [],
    this.expenseByProject = const [],
    this.incomeByProject = const [],
    this.statsStatus = const Status.initial(),
    this.labelsStatus = const Status.initial(),
  });

  factory ReportsState.initial([DateTime? now]) {
    final range = ReportRange.preset(
      DateRangePreset.thisMonth,
      CalendarDay.today(now),
    );
    return ReportsState(
      range: range,
      granularity: ReportAggregator.defaultGranularity(range),
    );
  }

  final String? businessId;
  final Currency currency;

  // --- Filters ---------------------------------------------------------------
  final ReportRange range;
  final ReportGranularity granularity;

  /// One category, project or type; `null` for the whole business.
  final ReportScope? scope;

  // --- Data ------------------------------------------------------------------
  final ReportLabels labels;

  /// The raw stats days for [range], kept so filter changes that do not move
  /// the range recompute locally without a new query.
  final List<DailyStats> days;
  final StatsTotals totals;
  final List<StatsBucket> series;
  final List<BreakdownEntry> incomeByCategory;
  final List<BreakdownEntry> expenseByCategory;
  final List<BreakdownEntry> incomeByProject;
  final List<BreakdownEntry> expenseByProject;

  final Status statsStatus;
  final Status labelsStatus;

  /// Cash is not split by category/project/type on the server.
  bool get showsCash => scope == null;

  ReportsState copyWith({
    String? businessId,
    Currency? currency,
    ReportRange? range,
    ReportGranularity? granularity,
    ReportScope? scope,
    bool clearScope = false,
    ReportLabels? labels,
    List<DailyStats>? days,
    StatsTotals? totals,
    List<StatsBucket>? series,
    List<BreakdownEntry>? incomeByCategory,
    List<BreakdownEntry>? expenseByCategory,
    List<BreakdownEntry>? incomeByProject,
    List<BreakdownEntry>? expenseByProject,
    Status? statsStatus,
    Status? labelsStatus,
  }) => ReportsState(
    businessId: businessId ?? this.businessId,
    currency: currency ?? this.currency,
    range: range ?? this.range,
    granularity: granularity ?? this.granularity,
    scope: clearScope ? null : scope ?? this.scope,
    labels: labels ?? this.labels,
    days: days ?? this.days,
    totals: totals ?? this.totals,
    series: series ?? this.series,
    incomeByCategory: incomeByCategory ?? this.incomeByCategory,
    expenseByCategory: expenseByCategory ?? this.expenseByCategory,
    incomeByProject: incomeByProject ?? this.incomeByProject,
    expenseByProject: expenseByProject ?? this.expenseByProject,
    statsStatus: statsStatus ?? this.statsStatus,
    labelsStatus: labelsStatus ?? this.labelsStatus,
  );

  @override
  List<Object?> get props => [
    businessId,
    currency,
    range,
    granularity,
    scope,
    labels,
    days,
    totals,
    series,
    incomeByCategory,
    expenseByCategory,
    incomeByProject,
    expenseByProject,
    statsStatus,
    labelsStatus,
  ];
}
