import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/features/documents/domain/models/json_reader.dart';
import 'package:equatable/equatable.dart';

/// The few transaction fields the dashboard lists need. A read model, not
/// the full `Transaction` (built in the transactions feature).
class TransactionRow extends Equatable {
  const TransactionRow({
    required this.id,
    required this.type,
    required this.status,
    this.direction,
    this.description = '',
    this.partyName,
    this.categoryName,
    this.date,
    this.dueDate,
    this.totalMinor = 0,
    this.outstandingMinor = 0,
    this.paymentStatus,
  });

  /// Drafts may lack most fields; confirmed entries have them all.
  factory TransactionRow.fromMap(String id, Map<String, dynamic> map) {
    final json = JsonReader(map, 'transactions/$id');
    final direction = json.optionalString('direction');
    final paymentStatus = json.optionalString('paymentStatus');
    return TransactionRow(
      id: id,
      type: TransactionType.fromKey(json.string('type')),
      status: TransactionStatus.fromKey(json.string('status')),
      direction: direction == null ? null : Direction.fromKey(direction),
      description: json.text('description'),
      partyName: json.optionalString('partyName'),
      categoryName: json.optionalString('categoryName'),
      date: json.optionalDate('date'),
      dueDate: json.optionalDate('dueDate'),
      totalMinor: json.intOrZero('totalMinor'),
      outstandingMinor: json.intOrZero('outstandingMinor'),
      paymentStatus: paymentStatus == null
          ? null
          : PaymentStatus.fromKey(paymentStatus),
    );
  }

  final String id;
  final TransactionType type;
  final TransactionStatus status;

  /// `null` on a payment/adjustment draft whose direction is not chosen yet.
  final Direction? direction;
  final String description;
  final String? partyName;
  final String? categoryName;
  final String? date;
  final String? dueDate;
  final int totalMinor;
  final int outstandingMinor;
  final PaymentStatus? paymentStatus;

  /// The best one-line name: description, else party, else category, else
  /// the type.
  String get title {
    for (final candidate in [description, partyName, categoryName]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return type.label;
  }

  /// Computed, never stored: see `LedgerMath.isOverdue`.
  bool isOverdue(String today) => LedgerMath.isOverdue(
    status: status,
    outstanding: outstandingMinor,
    dueDate: dueDate,
    today: today,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    direction,
    description,
    partyName,
    categoryName,
    date,
    dueDate,
    totalMinor,
    outstandingMinor,
    paymentStatus,
  ];
}

/// What customers owe the business and what it owes suppliers: the sum of
/// `outstandingMinor` over open confirmed transactions.
class ReceivablesPayables extends Equatable {
  const ReceivablesPayables({
    required this.receivableMinor,
    required this.payableMinor,
    this.fromCache = false,
  });

  final int receivableMinor;
  final int payableMinor;

  /// Summed from locally cached documents because the server aggregate was
  /// unreachable; may be incomplete.
  final bool fromCache;

  @override
  List<Object?> get props => [receivableMinor, payableMinor, fromCache];
}

/// Display names for the ids found in stats.
class ReportLabels extends Equatable {
  const ReportLabels({this.categories = const {}, this.projects = const {}});

  static const ReportLabels empty = ReportLabels();

  final Map<String, String> categories;
  final Map<String, String> projects;

  @override
  List<Object?> get props => [categories, projects];
}
