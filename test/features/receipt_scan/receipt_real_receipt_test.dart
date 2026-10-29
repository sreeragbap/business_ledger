import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/services/receipt_ai_mapper.dart';
import 'package:business_ledger/features/receipt_scan/domain/services/receipt_parser.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real tyre-shop GST invoice (Tally layout, two columns, creased and
/// photographed at a tilt), as Apple Vision and Android ML Kit recognised
/// it. Buyer details redacted.
///
/// Printed: Calicut Tyres, Thondayad Bypass Road, Calicut; invoice 3335
/// dated 15-Mar-24;
/// 350/19 Michelin Sirac Street RTT 1 × 2,750.00 incl. tax (2,148.44 + tax),
/// 3.50/19 Michelin Tube 1 × 350.00 incl. tax (273.44 + tax);
/// SGST 14% 339.06, CGST 14% 339.06; total ₹3,100.00.
List<OcrLine> calicutTyres(String reader) {
  final raw =
      jsonDecode(
            File(
              'test/fixtures/receipts/calicut_tyres_$reader.json',
            ).readAsStringSync(),
          )
          as List<Object?>;
  return [for (final line in raw) OcrLine.fromMap(line! as Map)];
}

const tyre = '350/19 Michelin Sirac Street RTT';
const tube = '3.50/19 Michelin Tube';

void main() {
  // ML Kit's rows slope with the crease: names sit half a line below their
  // amounts across the page.
  // The second ML Kit scan misread "₹ 3,100.00" as "73,100.00", the tube's
  // "1 NOS" as "4 NOS" and put a space in the GSTIN. The third (ML Kit on
  // a photo) read the GSTIN's "5361" as "6361", put right from the PAN at
  // the foot, and split "(from 1-Apr-2021)" from the shop's name.
  for (final reader in ['vision', 'mlkit', 'mlkit_2', 'mlkit_3']) {
    group('on the device ($reader)', () {
      test('reads the total, date, shop and invoice number', () {
        final scan = ReceiptParser.parse(
          calicutTyres(reader),
          currency: Currency.inr,
          now: DateTime(2026, 10, 27),
        );
        expect(scan.totalMinor, 310000);
        expect(scan.date, '2024-03-15');
        expect(scan.merchant, 'Calicut Tyres');
        expect(scan.reference, '3335');
      });

      test('lists both items at their own price, then the GST', () {
        final scan = ReceiptParser.parse(
          calicutTyres(reader),
          currency: Currency.inr,
          now: DateTime(2026, 10, 27),
        );
        // Not the GST table under the total: it repeats these.
        expect(scan.lineItems, [
          LineItem.of(description: tyre, rateMinor: 214844),
          LineItem.of(description: tube, rateMinor: 27344),
          LineItem.of(description: 'SGST 14%', rateMinor: 33906),
          LineItem.of(description: 'CGST 14%', rateMinor: 33906),
        ]);
      });

      test("reads the seller's GSTIN, phone and email, not the buyer's", () {
        final scan = ReceiptParser.parse(
          calicutTyres(reader),
          currency: Currency.inr,
          now: DateTime(2026, 10, 27),
        );
        // OCR read the GSTIN's fixed "Z" as "2"; it is repaired.
        expect(scan.sellerGstin, '32AAHFC5361P1Z7');
        expect(scan.sellerPhone, '8606206660');
        expect(scan.sellerEmail, 'mail@calicuttyres.com');
        // The shop's column only, in its words; ML Kit's tilted rows may
        // put the lines out of order.
        expect(
          scan.sellerAddress,
          allOf(
            contains('THONDAYAD BYPASS ROAD'),
            contains('NEAR AZHATHRIKOVIL VISHNU TEMPLE'),
            contains('CALICUT'),
            isNot(contains('Delivery')),
          ),
        );
      });
    });
  }

  group('AI answers for this invoice', () {
    Map<String, dynamic> answer(List<Map<String, String>> lines) => {
      'merchant': 'Calicut Tyres',
      'date': '2024-03-15',
      'total': '3100.00',
      'currency': 'INR',
      'reference': '3335',
      'paymentMethod': null,
      'categoryId': null,
      'description': 'Michelin tyre and tube',
      'lineItems': lines,
    };

    test('tax-inclusive rates: one line per item, tyre and tube', () {
      final scan = ReceiptAiMapper.toScan(
        answer([
          {'description': tyre, 'quantity': '1', 'rate': '2750.00'},
          {'description': tube, 'quantity': '1', 'rate': '350.00'},
        ]),
        Currency.inr,
      );
      expect(scan.totalMinor, 310000);
      expect(scan.lineItems, [
        LineItem.of(description: tyre, rateMinor: 275000),
        LineItem.of(description: tube, rateMinor: 35000),
      ]);
    });

    test('pre-tax rates with the taxes as their own lines', () {
      final scan = ReceiptAiMapper.toScan(
        answer([
          {'description': tyre, 'quantity': '1', 'rate': '2148.44'},
          {'description': tube, 'quantity': '1', 'rate': '273.44'},
          {'description': 'SGST 14%', 'quantity': '1', 'rate': '339.06'},
          {'description': 'CGST 14%', 'quantity': '1', 'rate': '339.06'},
        ]),
        Currency.inr,
      );
      expect(scan.lineItems.map((l) => l.amountMinor), [
        214844,
        27344,
        33906,
        33906,
      ]);
      expect(LineItem.total(scan.lineItems), 310000);
    });

    test('pre-tax rates alone: the taxes become one charges line', () {
      final scan = ReceiptAiMapper.toScan(
        answer([
          {'description': tyre, 'quantity': '1', 'rate': '2148.44'},
          {'description': tube, 'quantity': '1', 'rate': '273.44'},
        ]),
        Currency.inr,
      );
      expect(scan.totalMinor, 310000);
      expect(scan.lineItems, [
        LineItem.of(description: tyre, rateMinor: 214844),
        LineItem.of(description: tube, rateMinor: 27344),
        LineItem.of(description: 'Taxes & other charges', rateMinor: 67812),
      ]);
    });

    test('a printed round-off up to one rupee becomes its own line', () {
      final scan = ReceiptAiMapper.toScan(
        answer([
          {'description': tyre, 'quantity': '1', 'rate': '2749.50'},
          {'description': tube, 'quantity': '1', 'rate': '350.00'},
        ]),
        Currency.inr,
      );
      expect(
        scan.lineItems.last,
        LineItem.of(
          description: 'Round off',
          rateMinor: 50,
        ),
      );
      expect(LineItem.total(scan.lineItems), 310000);
    });
  });
}
