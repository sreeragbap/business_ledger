import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:equatable/equatable.dart';

/// Where the receipt image comes from.
enum ReceiptSource { camera, photos }

/// Who understood the receipt text.
enum ReceiptReader {
  /// Claude, through the `scan-receipt` Edge Function.
  ai,

  /// The on-device heuristics (`ReceiptParser`), offline or as a fallback.
  device,
}

/// What was read off a receipt. Every field is optional: a blurry photo may
/// give only the total.
///
/// Only the text survives; the image is deleted once read (the app stores no
/// files).
class ReceiptScan extends Equatable {
  const ReceiptScan({
    this.totalMinor,
    this.date,
    this.merchant,
    this.reference,
    this.paymentMethod,
    this.categoryId,
    this.description,
    this.lineItems = const [],
    this.sellerGstin,
    this.sellerPhone,
    this.sellerEmail,
    this.sellerAddress,
    this.reader = ReceiptReader.device,
  });

  /// Minor units of the business currency.
  final int? totalMinor;

  /// `yyyy-MM-dd`.
  final String? date;
  final String? merchant;
  final String? reference;

  /// One of `PaymentMethods.common`.
  final String? paymentMethod;

  /// A category the business already has (AI only).
  final String? categoryId;

  /// A short note of what was bought (AI only).
  final String? description;

  /// Items whose amounts add up exactly to [totalMinor], with a line for
  /// what the items leave out when needed (see [balanced]).
  final List<LineItem> lineItems;

  /// The seller as printed: tax number, contact, address.
  final String? sellerGstin;
  final String? sellerPhone;
  final String? sellerEmail;
  final String? sellerAddress;
  final ReceiptReader reader;

  /// The seller's details as one line for the notes, or `null`.
  String? get sellerSummary {
    final parts = [
      if (sellerGstin case final gstin?) 'GSTIN $gstin',
      if (sellerPhone case final phone?) 'Ph $phone',
      ?sellerEmail,
      ?sellerAddress,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// The line [balanced] adds for what the items leave out: the taxes and
  /// charges a reader could not match to the items.
  static const String otherCharges = 'Other charges';
  static const String taxesAndOtherCharges = 'Taxes & other charges';

  /// [lines] made to add up to [total] exactly, so a scanned receipt is
  /// always itemised with its own total:
  ///
  /// * a shortfall up to one major unit becomes a "Round off" line;
  /// * a larger one, one "Taxes & other charges" line ("Other charges"
  ///   when tax lines are already there);
  /// * lines above the total give none: a discount can't be a negative
  ///   line.
  static List<LineItem> balanced(
    List<LineItem> lines,
    int total,
    Currency currency,
  ) {
    if (lines.isEmpty || total <= 0) return const [];
    final shortBy = total - LineItem.total(lines);
    if (shortBy < 0) return const [];
    final result = [
      ...lines,
      if (shortBy > 0)
        LineItem.of(
          description: shortBy <= _oneMajorUnit(currency)
              ? 'Round off'
              : lines.any((line) => _taxLine.hasMatch(line.description))
              ? otherCharges
              : taxesAndOtherCharges,
          rateMinor: shortBy,
        ),
    ];
    return result.length > TransactionDraft.maxLineItems ? const [] : result;
  }

  static final RegExp _taxLine = RegExp(
    r'\b(gst|cgst|sgst|igst|utgst|vat|cess|tax)\b',
    caseSensitive: false,
  );

  static int _oneMajorUnit(Currency currency) {
    var unit = 1;
    for (var i = 0; i < currency.decimals; i++) {
      unit *= 10;
    }
    return unit;
  }

  /// Whether a balancing line stands in for charges the reader couldn't
  /// match: lines that add up on their own are the better reading.
  bool get hasUnmatchedCharges => hasStandInCharges(lineItems);

  /// Whether [line] is a tax, round-off or charges line rather than
  /// something bought.
  static bool isCharge(LineItem line) =>
      _taxLine.hasMatch(line.description) ||
      line.description == 'Round off' ||
      line.description == otherCharges ||
      line.description == taxesAndOtherCharges;

  /// Whether [lines] end in the charges line [balanced] adds.
  static bool hasStandInCharges(List<LineItem> lines) => lines.any(
    (line) =>
        line.description == otherCharges ||
        line.description == taxesAndOtherCharges,
  );

  bool get isEmpty =>
      totalMinor == null &&
      date == null &&
      merchant == null &&
      reference == null &&
      paymentMethod == null &&
      categoryId == null &&
      description == null &&
      lineItems.isEmpty &&
      sellerSummary == null;

  /// This scan, with gaps filled from [other] (the AI answer first, the
  /// on-device reading for what it left out).
  ReceiptScan orElse(ReceiptScan other) => ReceiptScan(
    totalMinor: totalMinor ?? other.totalMinor,
    date: date ?? other.date,
    merchant: merchant ?? other.merchant,
    reference: reference ?? other.reference,
    paymentMethod: paymentMethod ?? other.paymentMethod,
    categoryId: categoryId ?? other.categoryId,
    description: description ?? other.description,
    // Lines belong to their own total: the other reader's only when its
    // total is the one kept, and when they are missing here or the other's
    // add up without a stand-in charges line.
    lineItems: _keepOwnLines(other) ? lineItems : other.lineItems,
    sellerGstin: sellerGstin ?? other.sellerGstin,
    sellerPhone: sellerPhone ?? other.sellerPhone,
    sellerEmail: sellerEmail ?? other.sellerEmail,
    sellerAddress: sellerAddress ?? other.sellerAddress,
    reader: reader,
  );

  bool _keepOwnLines(ReceiptScan other) {
    if (other.totalMinor != (totalMinor ?? other.totalMinor)) return true;
    if (other.lineItems.isEmpty) return true;
    if (lineItems.isEmpty) return false;
    return !hasUnmatchedCharges || other.hasUnmatchedCharges;
  }

  @override
  List<Object?> get props => [
    totalMinor,
    date,
    merchant,
    reference,
    paymentMethod,
    categoryId,
    description,
    lineItems,
    sellerGstin,
    sellerPhone,
    sellerEmail,
    sellerAddress,
    reader,
  ];
}
