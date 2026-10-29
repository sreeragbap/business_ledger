import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';

/// Turns the `scan-receipt` answer into a [ReceiptScan] in minor units.
///
/// The server already cleaned the answer; this is where money is made
/// exact, with the app's own rules:
/// * amounts parse with [Money] (extra decimals are cut, never rounded up);
/// * a total in another currency than the business's is dropped;
/// * line items are made to add up to the total exactly
///   ([ReceiptScan.balanced]), so a filled form is itemised and balances:
///   a shortfall becomes a "Round off" or "Taxes & other charges" line;
///   lines above the total, or far below it, are dropped and the total
///   kept.
abstract final class ReceiptAiMapper {
  static ReceiptScan toScan(Map<String, dynamic> json, Currency currency) {
    final otherCurrency = switch (json['currency']) {
      final String code => code.toUpperCase() != currency.code,
      _ => false,
    };
    final total = otherCurrency
        ? null
        : _minor(json['total'] as String?, currency);
    final lines = total == null
        ? const <LineItem>[]
        : _lines(json['lineItems'], currency, total);
    final date = json['date'] as String?;
    final method = json['paymentMethod'] as String?;
    return ReceiptScan(
      totalMinor: total,
      date: LedgerDates.isValid(date) ? date : null,
      merchant: _text(json['merchant'], 60),
      reference: _text(json['reference'], TransactionDraft.maxReferenceLength),
      paymentMethod: PaymentMethods.common.contains(method) ? method : null,
      categoryId: _text(json['categoryId'], 100),
      description: _text(
        json['description'],
        TransactionDraft.maxDescriptionLength,
      ),
      lineItems: lines,
      sellerGstin: _text(json['sellerGstin'], 15),
      sellerPhone: _text(json['sellerPhone'], 30),
      sellerEmail: _text(json['sellerEmail'], 80),
      sellerAddress: _text(json['sellerAddress'], 160),
      reader: ReceiptReader.ai,
    );
  }

  static List<LineItem> _lines(Object? raw, Currency currency, int total) {
    if (raw is! List || raw.isEmpty) return const [];
    final lines = <LineItem>[];
    for (final item in raw) {
      if (item is! Map) return const [];
      final map = item.cast<String, dynamic>();
      final quantity = Money.parseQuantityMilli(map.readString('quantity'));
      final rate = _minor(map.readString('rate'), currency);
      final description = _text(
        map['description'],
        LineItem.maxDescriptionLength,
      );
      if (quantity == null || quantity == 0 || rate == null) return const [];
      lines.add(
        LineItem.of(
          description: description ?? '',
          quantityMilli: quantity,
          rateMinor: rate,
        ),
      );
    }
    return ReceiptScan.balanced(lines, total, currency);
  }

  /// `"1234.567"` → minor units, cutting digits beyond the currency's.
  static int? _minor(String? value, Currency currency) {
    if (value == null) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(value.trim());
    if (match == null) return null;
    final fraction = match.group(2) ?? '';
    final kept = fraction.length > currency.decimals
        ? fraction.substring(0, currency.decimals)
        : fraction;
    final minor = Money.parse(
      kept.isEmpty ? match.group(1)! : '${match.group(1)}.$kept',
      currency,
    );
    return minor == null || minor == 0 ? null : minor;
  }

  static String? _text(Object? value, int max) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > max ? trimmed.substring(0, max) : trimmed;
  }
}
