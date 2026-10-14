import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const inr = Currency.inr;
  const jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
  const kwd = Currency(code: 'KWD', decimals: 3, symbol: 'KWD ');

  group('parse', () {
    test('reads whole and fractional amounts exactly', () {
      expect(Money.parse('1250', inr), 125000);
      expect(Money.parse('1,250.5', inr), 125050);
      expect(Money.parse('0.1', inr), 10);
      expect(Money.parse('0.01', inr), 1);
      expect(Money.parse('007.10', inr), 710);
      expect(Money.parse('12.', inr), 1200);
    });

    test('respects the currency precision', () {
      expect(Money.parse('5', jpy), 5);
      expect(Money.parse('5.1', jpy), isNull);
      expect(Money.parse('1.234', kwd), 1234);
      expect(Money.parse('1.2345', kwd), isNull);
    });

    test('refuses anything that is not a plain non-negative amount', () {
      for (final input in <String>[
        '',
        ' ',
        '-1',
        '1e3',
        'abc',
        '1.2.3',
        '.5',
        '1.001',
      ]) {
        expect(Money.parse(input, inr), isNull, reason: input);
      }
    });

    test('refuses amounts above the ceiling', () {
      expect(Money.parse('100000000000', inr), Money.maxMinor);
      expect(Money.parse('100000000000.01', inr), isNull);
      expect(Money.parse('9' * 40, inr), isNull);
    });
  });

  group('format', () {
    test('groups and pads', () {
      expect(Money.format(125050, inr), '₹1,250.50');
      expect(Money.format(5, inr), '₹0.05');
      expect(Money.format(0, inr), '₹0.00');
      expect(Money.format(-5000, inr), '-₹50.00');
      expect(Money.format(1500, jpy), '¥1,500');
      expect(Money.format(1234, kwd), 'KWD 1.234');
    });

    test('plain round-trips through parse', () {
      for (final minor in <int>[0, 1, 99, 100, 123456789, Money.maxMinor]) {
        expect(Money.parse(Money.plain(minor, inr), inr), minor);
      }
    });
  });

  test('quantity formatting', () {
    expect(Money.parseQuantityMilli('2.5'), 2500);
    expect(Money.quantity(2500), '2.5');
    expect(Money.quantity(3000), '3');
    expect(Money.quantity(1005), '1.005');
  });
}
