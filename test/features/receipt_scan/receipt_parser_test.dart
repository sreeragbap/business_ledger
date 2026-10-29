import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/domain/services/receipt_parser.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// One recognised line per printed row, stacked top to bottom.
List<OcrLine> rows(String text) => [
  for (final (i, row) in text.trim().split('\n').indexed)
    OcrLine(
      text: row.trim(),
      left: 0,
      top: i * 10.0,
      right: 100,
      bottom: i * 10.0 + 8,
    ),
];

final now = DateTime(2026, 10, 26, 15);

ReceiptScan parse(String text, {Currency currency = Currency.inr}) =>
    ReceiptParser.parse(rows(text), currency: currency, now: now);

void main() {
  group('groupRows', () {
    test('joins a label and its amount printed on the same row', () {
      final grouped = ReceiptParser.groupRows(const [
        OcrLine(text: '1,240.00', left: 70, top: 101, right: 95, bottom: 109),
        OcrLine(text: 'Grand Total', left: 5, top: 100, right: 40, bottom: 110),
        OcrLine(text: 'Thank you', left: 20, top: 130, right: 60, bottom: 140),
      ]);
      expect(grouped, ['Grand Total  1,240.00', 'Thank you']);
    });

    test('follows rows that slope on a tilted photo', () {
      // Each printed row climbs 30 px across 2000 px: the name sits lower
      // than its amount by more than half a line.
      OcrLine at(String text, double left, double row) {
        final top = row * 60 - left * 0.015;
        return OcrLine(
          text: text,
          left: left,
          top: top,
          right: left + 300,
          bottom: top + 36,
        );
      }

      final grouped = ReceiptParser.groupRows([
        for (var row = 0; row < 6; row++) ...[
          at('Item $row', 0, row.toDouble()),
          at('1 NOS', 900, row.toDouble()),
          at('${row + 1}00.00', 1700, row.toDouble()),
        ],
      ]);
      expect(grouped, [
        for (var row = 0; row < 6; row++) 'Item $row  1 NOS  ${row + 1}00.00',
      ]);
    });

    test('lines stacked in one column stay on their own rows', () {
      final grouped = ReceiptParser.groupRows(const [
        OcrLine(text: 'CALICUT TYRES', left: 0, top: 0, right: 300, bottom: 30),
        OcrLine(text: 'BYPASS ROAD', left: 0, top: 12, right: 280, bottom: 42),
      ]);
      expect(grouped, ['CALICUT TYRES', 'BYPASS ROAD']);
    });

    test('orders rows top to bottom whatever order they arrive in', () {
      final grouped = ReceiptParser.groupRows(const [
        OcrLine(text: 'second', left: 0, top: 20, right: 10, bottom: 28),
        OcrLine(text: 'first', left: 0, top: 0, right: 10, bottom: 8),
      ]);
      expect(grouped, ['first', 'second']);
    });
  });

  test('an Indian GST supermarket bill', () {
    final scan = parse('''
      RELIANCE FRESH
      Shop 4, MG Road, Kochi 682016
      GSTIN: 32AABCR1718E1ZL
      TAX INVOICE
      Bill No: RF/2026/04821    Date: 24/10/2026 18:42
      Toor Dal 1kg   2   145.00   290.00
      Basmati Rice 5kg   1   620.00
      Sub Total   910.00
      CGST 2.5%   22.75
      SGST 2.5%   22.75
      Round Off   -0.50
      Grand Total   955.00
      Paid by UPI
      Thank you, visit again
    ''');
    expect(scan.totalMinor, 95500);
    expect(scan.date, '2026-10-24');
    expect(scan.merchant, 'Reliance Fresh');
    expect(scan.reference, 'RF/2026/04821');
    expect(scan.paymentMethod, 'UPI');
  });

  test('a restaurant bill with the amount on the next row', () {
    final scan = parse('''
      Hotel Saravana Bhavan
      Ph: 0484 2345678
      Table 7   Covers 2
      Date: 12-Oct-26
      Masala Dosa x2   180.00
      Filter Coffee x2   80.00
      Total Qty: 4
      Net Amount
      273.00
      CASH   300.00
      Change   27.00
    ''');
    expect(scan.totalMinor, 27300);
    expect(scan.date, '2026-10-12');
    expect(scan.merchant, 'Hotel Saravana Bhavan');
    expect(scan.paymentMethod, 'Cash');
  });

  test('a card slip with the month spelt out', () {
    final scan = parse('''
      Indian Oil Fuel Station
      Invoice No. 55021
      Oct 3, 2026   09:15
      Petrol 30.5 L @ 104.20
      Total Amount Rs. 3,178.10
      VISA **** 4421
    ''');
    expect(scan.totalMinor, 317810);
    expect(scan.date, '2026-10-03');
    expect(scan.reference, '55021');
    expect(scan.paymentMethod, 'Card');
  });

  test('a US receipt reads the date month first', () {
    final scan = parse(r'''
      Corner Hardware
      03/04/2026
      Hammer   12.99
      Nails   4.50
      Subtotal   17.49
      Tax   1.40
      Total   $18.89
    ''', currency: const Currency(code: 'USD', decimals: 2, symbol: r'$'));
    expect(scan.totalMinor, 1889);
    expect(scan.date, '2026-03-04');
  });

  test('day first elsewhere, and a part above 12 is always the day', () {
    expect(parse('Date 03/04/2026').date, '2026-04-03');
    expect(parse('Date 10/25/2026').date, '2026-10-25');
  });

  test('a "from" date in the shop name is not the bill date', () {
    // How Android's recogniser grouped the tyre invoice: the "Dated" label
    // alone, its date on another line, the shop's "(from …)" note above.
    final scan = parse('''
      CALICUT TYRES - (from 1-Apr-2021)
      Invoice No.  Dated
      3335  15-Mar-24
      Total  3,100.00
    ''');
    expect(scan.date, '2024-03-15');
  });

  test('without a date label the latest date is the bill date', () {
    final scan = parse('''
      Est. 12/01/2009
      Valid till 31/03/2027
      Reg 05/06/2019
      10/09/2026
      Total 50.00
    ''');
    expect(scan.date, '2026-09-10');
  });

  test('due dates are not the bill date', () {
    expect(
      parse('Due date 30/10/2026\nBill date 01/10/2026').date,
      '2026-10-01',
    );
  });

  test('restaurant items with "x2" quantities', () {
    final scan = parse('''
      Hotel Saravana Bhavan
      Masala Dosa x2   180.00
      Filter Coffee x2   80.00
      Net Amount   260.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Masala Dosa', 18000),
      ('Filter Coffee', 8000),
    ]);
    // Printed as line amounts: the rate is per unit.
    expect(scan.lineItems.first.rateMinor, 9000);
  });

  test('pre-tax items with the tax lines added to reach the total', () {
    final scan = parse('''
      Corner Hardware
      Hammer   1 pcs   500.00
      Nails box   2 pcs   100.00
      CGST 9%   63.00
      SGST 9%   63.00
      Grand Total   826.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Hammer', 50000),
      ('Nails box', 20000),
      ('CGST 9%', 6300),
      ('SGST 9%', 6300),
    ]);
  });

  test('a round-off printed after the taxes completes the pre-tax items', () {
    final scan = parse('''
      1 Clutch Set   1 Nos   5,042.37
      2 Bearing   1 Nos   1,228.81
      CGST 9%   564.40
      SGST 9%   564.40
      Round Off   0.02
      Total   7,400.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Clutch Set', 504237),
      ('Bearing', 122881),
      ('CGST 9%', 56440),
      ('SGST 9%', 56440),
      ('Round off', 2),
    ]);
  });

  test('a serial number read without its space is not in the name', () {
    final scan = parse('''
      1Clutch Set   1 Nos   5,950.00
      Total   5,950.00
    ''');
    expect(scan.lineItems.single.description, 'Clutch Set');
  });

  test('a comma read as a dot still makes the amount', () {
    final scan = parse('''
      Clutch Set   1 Nos   5.950.00
      Bearing   1 Nos   1,450.00
      Total   7,400.00
    ''');
    expect(scan.lineItems.map((l) => l.rateMinor), [595000, 145000]);
    expect(parse('Total   5.95').totalMinor, 595);
  });

  test('letters ML Kit reads as Polish are put back', () {
    final scan = parse('''
      Invoicę No.   Dated
      Hindustan Automobiłes   HAM8769/26-27   27-Oct-26
      Total   100.00
    ''');
    expect(scan.merchant, 'Hindustan Automobiles');
    expect(scan.reference, 'HAM8769/26-27');
  });

  test('a bill number with a year range is not a date', () {
    expect(parse('Invoice No. HAM8769/26-27').reference, 'HAM8769/26-27');
    expect(parse('Invoice No. 12/03/2024').reference, isNull);
  });

  test('a month whose O was read as a zero', () {
    expect(parse('Dated 25-0ct-26').date, '2026-10-25');
  });

  test("a mobile number printed alone is the seller's phone", () {
    final scan = parse('''
      Hindustan Automobiles
      0495-2361356, 2361678
      9349112874
      Buyer (Bill to)
      9000000000
    ''');
    expect(scan.sellerPhone, '9349112874');
  });

  test('items short of the total are kept, with a line for the rest', () {
    // GST charged but its lines not read.
    final scan = parse('''
      Hammer   1 pcs   500.00
      Nails box   2 pcs   100.00
      Grand Total   826.00
    ''');
    expect(scan.totalMinor, 82600);
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Hammer', 50000),
      ('Nails box', 20000),
      ('Taxes & other charges', 12600),
    ]);
  });

  test('read taxes come first; what is still missing is other charges', () {
    final scan = parse('''
      Hammer   1 pcs   500.00
      Nails box   2 pcs   100.00
      CGST 9%   63.00
      SGST 9%   63.00
      Packing   10.00
      Grand Total   836.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Hammer', 50000),
      ('Nails box', 20000),
      ('CGST 9%', 6300),
      ('SGST 9%', 6300),
      ('Other charges', 1000),
    ]);
  });

  test('the GST summary table below the total is not read as lines', () {
    // The table repeats taxes already in the bill: its rows are neither
    // items nor tax lines, and its "Total" row is not the bill's.
    final scan = parse('''
      Description   Qty   Amount
      Item A   1 pcs   1,000.00
      Item B   1 pcs   500.00
      Grand Total   1,575.00
      HSN/SAC   Taxable Value   CGST   SGST   Total
      8409   1 pcs   1,500.00
      CGST 2.5%   1,500.00   37.50
      SGST 2.5%   1,500.00   37.50
      Total   1,500.00   37.50   37.50   75.00
    ''');
    expect(scan.totalMinor, 157500);
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Item A', 100000),
      ('Item B', 50000),
      ('Taxes & other charges', 7500),
    ]);
  });

  test('the GST printed in the bill shows as its own lines', () {
    // Both readings add up; the one with the GST on its own lines wins.
    final scan = parse('''
      Tyre   1 NOS   2,750.00   2,148.44
      OUTPUT SGST (@14%   14 %   339.06
      OUTPUT CGST @ 14%   14 %   339.06
      Tube   1 NOS   350.00   273.44
      Total   3,100.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Tyre', 214844),
      ('Tube', 27344),
      ('SGST 14%', 33906),
      ('CGST 14%', 33906),
    ]);
  });

  test("a tax line's amount moved to a row of its own is still found", () {
    final scan = parse('''
      Tyre   1 NOS   2,148.44
      Tube   1 NOS   273.44
      339.06
      OUTPUT SGST @14%   14%   339.06
      OUTPUT CGST@ 14%   14%
      Total   3,100.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Tyre', 214844),
      ('Tube', 27344),
      ('SGST 14%', 33906),
      ('CGST 14%', 33906),
    ]);
  });

  test("the shop's address: its column, up to the contact lines", () {
    final scan = parse('''
      Hindustan Automobiles   Invoice No.
      5/1239-East Nadakkavu   HAM8769/26-27   Dated
      Kozhikode-673006   Delivery Note   27-Oct-26
      0495-2361356, 2361678
      GSTIN/UIN: 32AABFH4578H1ZG
    ''');
    expect(scan.sellerAddress, '5/1239-East Nadakkavu, Kozhikode-673006');
  });

  test('names on rows of their own go to the quantity rows in order', () {
    final scan = parse('''
      Description of Goods   Quantity   Rate   Amount
      Clutch Set
      2 Bearing   840999   1 Nos   5,950.00
      4016   1 Nos   1,450.00
      Total   7,400.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Clutch Set', 595000),
      ('Bearing', 145000),
    ]);
  });

  test('names and quantity rows that are not as many are not paired', () {
    // "RTT" wraps the tyre's name: three names, two rows.
    final scan = parse('''
      Description of Goods   Quantity   Amount
      350/19 Michelin Sirac Street   1 NOS   2,750.00
      RTT
      3.50/19 Michelin Tube   1 NOS   350.00
      Total   3,100.00
    ''');
    expect(scan.lineItems.map((l) => l.description), [
      '350/19 Michelin Sirac Street RTT',
      '3.50/19 Michelin Tube',
    ]);
  });

  test('items above the total are left out', () {
    final scan = parse('''
      Hammer   1 pcs   500.00
      Total   450.00
    ''');
    expect(scan.totalMinor, 45000);
    expect(scan.lineItems, isEmpty);
  });

  test('every item is listed, however much the charges line holds', () {
    final scan = parse('''
      Hammer   1 pcs   100.00
      Total   999.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      ('Hammer', 10000),
      ('Taxes & other charges', 89900),
    ]);
  });

  test('a quantity read as "1 N0S" still makes an item', () {
    final scan = parse('''
      Tube   1 N0S   350.00
      Total   350.00
    ''');
    expect(scan.lineItems.single.description, 'Tube');
  });

  test('without any readable quantity, named rows with an amount count', () {
    final scan = parse('''
      Description of Goods   Amount
      1 350/19 Michelin Sirac Street   2,750.00
      RTT   2,148.44
      2 3.50/19 Michelin Tube   350.00
      Total   3,100.00
    ''');
    expect(scan.lineItems.map((l) => (l.description, l.amountMinor)), [
      // "RTT" is the name wrapping onto the next line.
      ('350/19 Michelin Sirac Street RTT', 275000),
      ('3.50/19 Michelin Tube', 35000),
    ]);
  });

  group('checked total', () {
    test('a ₹ read as 7 is dropped when the amount in words says so', () {
      final scan = parse('''
        Total   73,100.00
        Amount Chargeable (in words)
        INR Three Thousand One Hundred Only
      ''');
      expect(scan.totalMinor, 310000);
    });

    test('a ₹ read as 7 is dropped when the items add up without it', () {
      final scan = parse('''
        Hammer   1 pcs   2,000.00
        Nails   1 pcs   1,100.00
        Total   73,100.00
      ''');
      expect(scan.totalMinor, 310000);
      expect(scan.lineItems, hasLength(2));
    });

    test('a total starting with 7 stays when nothing disproves it', () {
      expect(parse('Total   7,450.00').totalMinor, 745000);
      expect(
        parse('''
          Total   73,100.00
          Rupees Seventy Three Thousand One Hundred Only
        ''').totalMinor,
        7310000,
      );
    });

    test('amounts in words: lakhs, "and", paise; tax in words is skipped', () {
      final scan = parse('''
        Tax Amount (in words): INR Six Hundred Seventy Eight and Twelve paise Only
        Grand Total   1,25,678.12
        Rupees One Lakh Twenty Five Thousand Six Hundred and Seventy Eight and Twelve Paise Only
      ''');
      expect(scan.totalMinor, 12567812);
    });
  });

  group('checked quantity', () {
    test('a misread quantity gives way to rate and amount that agree', () {
      final scan = parse('''
        Tube   4 NOS   350.00   350.00
        Tyre   1 NOS   2,750.00   2,750.00
        Total   3,100.00
      ''');
      expect(scan.lineItems.map((l) => (l.quantityMilli, l.rateMinor)), [
        (1000, 35000),
        (1000, 275000),
      ]);
    });

    test('a quantity the amounts confirm is kept', () {
      final scan = parse('''
        Toor Dal   2 pcs   145.00   290.00
        Total   290.00
      ''');
      expect(scan.lineItems.single.quantityMilli, 2000);
      expect(scan.lineItems.single.rateMinor, 14500);
    });
  });

  group('GSTIN', () {
    String? gstin(String text) => parse(text).sellerGstin;

    test('kept only when its check character is right', () {
      expect(gstin('GSTIN: 32AAHFC5361P1Z7'), '32AAHFC5361P1Z7');
      expect(gstin('GSTIN: 32AAHFC5361P1Z8'), isNull);
    });

    test('a digit misread inside it is put right from the PAN', () {
      expect(
        gstin("GSTIN/UIN: 32AAHFC6361P1Z7\nBuyer\nCompany's PAN  AAHFO5361 P"),
        '32AAHFC5361P1Z7',
      );
      // No PAN to compare with: left out rather than guessed.
      expect(gstin('GSTIN/UIN: 32AAHFC6361P1Z7'), isNull);
    });

    test('look-alike misreads and a stray space are put right', () {
      expect(gstin('GSTIN/UIN: 32AAHFC5361 P127'), '32AAHFC5361P1Z7');
      expect(gstin('GSTIN: 3ZAAHFCS36IP1Z7'), '32AAHFC5361P1Z7');
    });
  });

  test('Indian digit grouping', () {
    expect(parse('Grand Total ₹1,23,456.50').totalMinor, 12345650);
  });

  test('ignores dates in the future and impossible dates', () {
    expect(parse('Date 30/12/2026').date, isNull);
    expect(parse('Date 31/02/2026').date, isNull);
  });

  test('subtotal and tax rows are not the total', () {
    final scan = parse('''
      Sub Total   500.00
      Taxable Amount   500.00
      GST   90.00
      Total   590.00
    ''');
    expect(scan.totalMinor, 59000);
  });

  test('without a total row the largest decimal amount is taken', () {
    final scan = parse('''
      Bread   40.00
      Milk   56.00
      Ph 9846012345
      152.00
    ''');
    expect(scan.totalMinor, 15200);
  });

  test('a note cut off in brackets is not part of the shop name', () {
    expect(
      parse('CALICUT TYRES (from   1-Apr-2021)').merchant,
      'Calicut Tyres',
    );
  });

  test('phone numbers and addresses are not the shop', () {
    final scan = parse('''
      Tel: 0484-2233445
      42 Market Road 682001
      Sunrise Bakery
    ''');
    expect(scan.merchant, 'Sunrise Bakery');
  });

  test('a cash memo heading does not mean paid in cash', () {
    expect(parse('CASH MEMO\nTotal 100.00').paymentMethod, isNull);
  });

  test('nothing readable gives an empty scan', () {
    expect(parse('~~~ ### ~~~').isEmpty, isTrue);
    expect(
      ReceiptParser.parse(const [], currency: Currency.inr, now: now),
      const ReceiptScan(),
    );
  });

  test('a zero-decimal currency drops the fraction', () {
    final scan = parse(
      'Total 1,500.00',
      currency: const Currency(code: 'JPY', decimals: 0, symbol: '¥'),
    );
    expect(scan.totalMinor, 1500);
  });

  test('items that add up beat ones that need a charges line', () {
    final exact = [
      LineItem.of(description: 'Clutch Set', rateMinor: 595000),
      LineItem.of(description: 'Bearing', rateMinor: 145000),
    ];
    final ai = ReceiptScan(
      totalMinor: 740000,
      lineItems: ReceiptScan.balanced(
        [
          LineItem.of(description: 'Clutch Set', rateMinor: 504237),
          LineItem.of(description: 'Bearing', rateMinor: 122881),
        ],
        740000,
        Currency.inr,
      ),
      reader: ReceiptReader.ai,
    );
    final device = ReceiptScan(totalMinor: 740000, lineItems: exact);
    expect(ai.lineItems.last.description, 'Taxes & other charges');
    expect(ai.orElse(device).lineItems, exact);
    // Lines that add up on their own stay.
    final aiExact = ReceiptScan(
      totalMinor: 740000,
      lineItems: exact,
      reader: ReceiptReader.ai,
    );
    expect(aiExact.orElse(ai).lineItems, exact);
  });

  test('the AI answer wins and the device reading fills its gaps', () {
    const ai = ReceiptScan(
      totalMinor: 100,
      categoryId: 'c1',
      reader: ReceiptReader.ai,
    );
    const device = ReceiptScan(
      totalMinor: 999,
      date: '2026-10-01',
      merchant: 'Shop',
    );
    expect(
      ai.orElse(device),
      const ReceiptScan(
        totalMinor: 100,
        date: '2026-10-01',
        merchant: 'Shop',
        categoryId: 'c1',
        reader: ReceiptReader.ai,
      ),
    );
  });
}
