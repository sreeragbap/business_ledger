import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:equatable/equatable.dart';

/// One `lineItems[]` row: quantity (thousandths) × rate (minor units).
///
/// [amountMinor] is always [Money.lineAmount] of the other two: the server
/// refuses a line whose amount does not match (`totalOf` in
/// `functions/src/handlers/transactions.ts`).
class LineItem extends Equatable {
  const LineItem({
    this.description = '',
    this.quantityMilli = 1000,
    this.rateMinor = 0,
    this.amountMinor = 0,
  });

  /// A line with its amount computed.
  factory LineItem.of({
    String description = '',
    int quantityMilli = 1000,
    int rateMinor = 0,
  }) => LineItem(
    description: description,
    quantityMilli: quantityMilli,
    rateMinor: rateMinor,
    amountMinor: Money.lineAmount(
      quantityMilli: quantityMilli,
      rateMinor: rateMinor,
    ),
  );

  factory LineItem.fromMap(Map<String, dynamic> map) => LineItem(
    description: map.readString('description'),
    quantityMilli: map.readInt('quantityMilli'),
    rateMinor: map.readInt('rateMinor'),
    amountMinor: map.readInt('amountMinor'),
  );

  /// `text(200)` in the functions schema.
  static const int maxDescriptionLength = 200;

  final String description;
  final int quantityMilli;
  final int rateMinor;
  final int amountMinor;

  bool get isConsistent =>
      amountMinor ==
      Money.lineAmount(quantityMilli: quantityMilli, rateMinor: rateMinor);

  /// Recomputes the amount after a change.
  LineItem copyWith({
    String? description,
    int? quantityMilli,
    int? rateMinor,
  }) => LineItem.of(
    description: description ?? this.description,
    quantityMilli: quantityMilli ?? this.quantityMilli,
    rateMinor: rateMinor ?? this.rateMinor,
  );

  Map<String, Object> toMap() => {
    'description': description.trim(),
    'quantityMilli': quantityMilli,
    'rateMinor': rateMinor,
    'amountMinor': amountMinor,
  };

  /// Sum of already-rounded lines (ARCHITECTURE §5, Rounding).
  static int total(Iterable<LineItem> lines) =>
      lines.fold(0, (sum, line) => sum + line.amountMinor);

  @override
  List<Object?> get props => [
    description,
    quantityMilli,
    rateMinor,
    amountMinor,
  ];
}
