import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/services/receipt_parser.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real spare-parts GST invoice (Tally layout, a "Rate (Incl. of Tax)"
/// column beside the pre-tax rate), as Apple Vision read a photo of it and
/// Android ML Kit read the document scanner's page. Buyer: "Cash".
///
/// Printed: Hindustan Automobiles, invoice HAM8769/26-27 dated 27-Oct-26;
/// 1 Clutch Set 1 × 5,950.00 incl. tax (5,042.37 + tax),
/// 2 Bearing 1 × 1,450.00 incl. tax (1,228.81 + tax);
/// CGST 9% 564.40, SGST 9% 564.40, Round Off 0.02; total ₹7,400.00.
List<OcrLine> hindustan(String reader) {
  final raw =
      jsonDecode(
            File(
              'test/fixtures/receipts/hindustan_automobiles_$reader.json',
            ).readAsStringSync(),
          )
          as List<Object?>;
  return [for (final line in raw) OcrLine.fromMap(line! as Map)];
}

void main() {
  // ML Kit read "5,950.00" as "5.950.00", "1 Clutch" as "1Clutch",
  // "27-Oct-26" as "27-0ct-26" and "Automobiles" / "Invoice" with Polish
  // letters. Its second scan (a curved page) left "Clutch Set" alone on a
  // row and put "2 Bearing" beside the clutch's amounts; it also read
  // "Ciutch" and "GSTINrUIN".
  const clutch = {'mlkit_2': 'Ciutch Set'};
  for (final reader in ['vision', 'mlkit', 'mlkit_2']) {
    test('on the device ($reader): items, total and details', () {
      final scan = ReceiptParser.parse(
        hindustan(reader),
        currency: Currency.inr,
        now: DateTime(2026, 10, 28),
      );
      expect(scan.totalMinor, 740000);
      // Each part at its own price, then the GST and round-off printed
      // above the total (not the GST table below it).
      expect(scan.lineItems, [
        LineItem.of(
          description: clutch[reader] ?? 'Clutch Set',
          rateMinor: 504237,
        ),
        LineItem.of(description: 'Bearing', rateMinor: 122881),
        LineItem.of(description: 'CGST 9%', rateMinor: 56440),
        LineItem.of(description: 'SGST 9%', rateMinor: 56440),
        LineItem.of(description: 'Round off', rateMinor: 2),
      ]);
      expect(
        scan.sellerAddress?.toLowerCase(),
        '5/1239-east nadakkavu, kozhikode-673006',
      );
      expect(scan.date, '2026-10-27');
      expect(scan.merchant, 'Hindustan Automobiles');
      expect(scan.reference, 'HAM8769/26-27');
      expect(scan.sellerGstin, '32AABFH4578H1ZG');
      expect(scan.sellerPhone, '9349112874');
      expect(scan.sellerEmail, 'hindustanmobiles@gmail.com');
    });
  }
}
