import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/domain/services/receipt_ai_mapper.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> answer([Map<String, dynamic> overrides = const {}]) => {
  'merchant': 'Reliance Fresh',
  'date': '2026-10-24',
  'total': '955.00',
  'currency': 'INR',
  'reference': 'RF/2026/04821',
  'paymentMethod': 'UPI',
  'categoryId': 'cat-groceries',
  'description': 'Groceries',
  'lineItems': [
    {'description': 'Toor Dal 1kg', 'quantity': '2', 'rate': '145.00'},
    {'description': 'Basmati Rice 5kg', 'quantity': '1', 'rate': '665.00'},
  ],
  ...overrides,
};

void main() {
  test('maps a full answer into minor units', () {
    final scan = ReceiptAiMapper.toScan(answer(), Currency.inr);
    expect(scan.totalMinor, 95500);
    expect(scan.date, '2026-10-24');
    expect(scan.merchant, 'Reliance Fresh');
    expect(scan.reference, 'RF/2026/04821');
    expect(scan.paymentMethod, 'UPI');
    expect(scan.categoryId, 'cat-groceries');
    expect(scan.description, 'Groceries');
    expect(scan.reader, ReceiptReader.ai);
    expect(scan.lineItems, [
      LineItem.of(
        description: 'Toor Dal 1kg',
        quantityMilli: 2000,
        rateMinor: 14500,
      ),
      LineItem.of(
        description: 'Basmati Rice 5kg',
        rateMinor: 66500,
      ),
    ]);
  });

  test('items short of the total keep it with a charges line', () {
    final scan = ReceiptAiMapper.toScan(
      answer({'total': '1000.00'}),
      Currency.inr,
    );
    expect(scan.totalMinor, 100000);
    expect(scan.lineItems.map((l) => l.description), [
      'Toor Dal 1kg',
      'Basmati Rice 5kg',
      'Taxes & other charges',
    ]);
    expect(scan.lineItems.last.amountMinor, 4500);
    expect(LineItem.total(scan.lineItems), 100000);
    expect(scan.hasUnmatchedCharges, isTrue);
  });

  test('drops items above the total: a discount cannot be a line', () {
    final above = ReceiptAiMapper.toScan(
      answer({'total': '900.00'}),
      Currency.inr,
    );
    expect(above.totalMinor, 90000);
    expect(above.lineItems, isEmpty);
  });

  test('drops line items with an unreadable quantity', () {
    final scan = ReceiptAiMapper.toScan(
      answer({
        'total': '145.00',
        'lineItems': [
          {'description': 'Dal', 'quantity': 'one', 'rate': '145.00'},
        ],
      }),
      Currency.inr,
    );
    expect(scan.lineItems, isEmpty);
    expect(scan.totalMinor, 14500);
  });

  test('a total in another currency is dropped, never converted', () {
    final scan = ReceiptAiMapper.toScan(
      answer({'currency': 'USD'}),
      Currency.inr,
    );
    expect(scan.totalMinor, isNull);
    expect(scan.lineItems, isEmpty);
    expect(scan.merchant, 'Reliance Fresh');
  });

  test('extra decimals are cut, not rounded', () {
    final scan = ReceiptAiMapper.toScan(
      answer({'total': '99.999', 'lineItems': <Object>[]}),
      Currency.inr,
    );
    expect(scan.totalMinor, 9999);
  });

  test('nulls and junk become empty fields', () {
    final scan = ReceiptAiMapper.toScan(
      {
        'merchant': '  ',
        'date': 'yesterday',
        'total': null,
        'currency': null,
        'reference': null,
        'paymentMethod': 'Barter',
        'categoryId': null,
        'description': null,
        'lineItems': 'none',
      },
      Currency.inr,
    );
    expect(scan.isEmpty, isTrue);
  });
}
