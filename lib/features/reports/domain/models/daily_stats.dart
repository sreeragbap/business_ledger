import 'package:business_ledger/features/documents/domain/models/json_reader.dart';
import 'package:equatable/equatable.dart';

/// Money in and out for one slice (a category, project or type), in minor
/// units. Values are deltas summed by the server and may in principle be
/// negative after a correction; consumers clamp where a share is drawn.
class InOut extends Equatable {
  const InOut({this.inMinor = 0, this.outMinor = 0});

  factory InOut.read(JsonReader json) =>
      InOut(inMinor: json.intOrZero('in'), outMinor: json.intOrZero('out'));

  static const InOut zero = InOut();

  final int inMinor;
  final int outMinor;

  int get net => inMinor - outMinor;
  bool get isZero => inMinor == 0 && outMinor == 0;

  InOut operator +(InOut other) => InOut(
    inMinor: inMinor + other.inMinor,
    outMinor: outMinor + other.outMinor,
  );

  @override
  List<Object?> get props => [inMinor, outMinor];

  @override
  String toString() => 'InOut(in: $inMinor, out: $outMinor)';
}

/// `businesses/{bid}/stats/{yyyy-MM-dd}`, maintained by the functions in
/// the same transaction as each financial write (`functions/src/lib/stats.ts`).
///
/// Every figure may be missing, meaning zero: the server only writes the
/// paths a delta touched.
class DailyStats extends Equatable {
  const DailyStats({
    required this.date,
    this.incomeMinor = 0,
    this.expenseMinor = 0,
    this.cashInMinor = 0,
    this.cashOutMinor = 0,
    this.byCategory = const {},
    this.byProject = const {},
    this.byType = const {},
  });

  /// Parses a stats document. The day comes from `date`, else the doc id.
  factory DailyStats.fromMap(String id, Map<String, dynamic> map) {
    final json = JsonReader(map, 'stats/$id');
    return DailyStats(
      date: json.has('date')
          ? json.date('date')
          : JsonReader({'id': id}).date('id'),
      incomeMinor: json.intOrZero('incomeMinor'),
      expenseMinor: json.intOrZero('expenseMinor'),
      cashInMinor: json.intOrZero('cashInMinor'),
      cashOutMinor: json.intOrZero('cashOutMinor'),
      byCategory: _slices(json, 'byCategory'),
      byProject: _slices(json, 'byProject'),
      byType: _slices(json, 'byType'),
    );
  }

  static Map<String, InOut> _slices(JsonReader json, String key) {
    final map = json.optionalMap(key);
    if (map == null) return const {};
    return {for (final id in map.keys) id: InOut.read(map.map(id))};
  }

  /// `yyyy-MM-dd`.
  final String date;

  /// Recognised income by transaction date (effective amount).
  final int incomeMinor;
  final int expenseMinor;

  /// Money actually received / paid, by settlement date.
  final int cashInMinor;
  final int cashOutMinor;
  final Map<String, InOut> byCategory;
  final Map<String, InOut> byProject;

  /// Keyed by `TransactionType.key`.
  final Map<String, InOut> byType;

  @override
  List<Object?> get props => [
    date,
    incomeMinor,
    expenseMinor,
    cashInMinor,
    cashOutMinor,
    byCategory,
    byProject,
    byType,
  ];
}
