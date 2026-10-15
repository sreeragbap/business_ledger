import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/reports/domain/models/daily_stats.dart';
import 'package:equatable/equatable.dart';

enum ReportDimension {
  category('Category'),
  project('Project'),
  type('Type');

  const ReportDimension(this.label);
  final String label;
}

/// Narrows a report to one category, project or transaction type.
///
/// Stats are kept per dimension, not per combination, so one dimension is
/// filtered at a time. Cash is not broken down by dimension on the server:
/// a scoped report shows income and expense only.
class ReportScope extends Equatable {
  const ReportScope({
    required this.dimension,
    required this.id,
    required this.label,
  });

  factory ReportScope.type(TransactionType type) => ReportScope(
    dimension: ReportDimension.type,
    id: type.key,
    label: type.label,
  );

  final ReportDimension dimension;
  final String id;
  final String label;

  /// This scope's slice of one day.
  InOut of(DailyStats day) {
    final slices = switch (dimension) {
      ReportDimension.category => day.byCategory,
      ReportDimension.project => day.byProject,
      ReportDimension.type => day.byType,
    };
    return slices[id] ?? InOut.zero;
  }

  @override
  List<Object?> get props => [dimension, id, label];
}
