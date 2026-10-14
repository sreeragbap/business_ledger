import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/widgets/app_money_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';

const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

void main() {
  group('AppMoneyField', () {
    Future<List<int?>> pumpField(
      WidgetTester tester, {
      Currency currency = Currency.inr,
      int? initialMinor,
    }) async {
      final values = <int?>[];
      await tester.pumpApp(
        AppMoneyField(
          currency: currency,
          initialMinor: initialMinor,
          onChanged: values.add,
        ),
      );
      return values;
    }

    testWidgets('yields integer minor units', (tester) async {
      final values = await pumpField(tester);
      await tester.enterText(find.byType(TextField), '1,250.5');
      expect(values.last, 125050);
    });

    testWidgets('refuses a third decimal for a 2-decimal currency', (
      tester,
    ) async {
      final values = await pumpField(tester);
      await tester.enterText(find.byType(TextField), '12.34');
      await tester.enterText(find.byType(TextField), '12.345');
      expect(find.text('12.34'), findsOneWidget);
      expect(values.last, 1234);
    });

    testWidgets('refuses a decimal point for a 0-decimal currency', (
      tester,
    ) async {
      final values = await pumpField(tester, currency: _jpy);
      await tester.enterText(find.byType(TextField), '500');
      await tester.enterText(find.byType(TextField), '500.5');
      expect(find.text('500'), findsOneWidget);
      expect(values.last, 500);
    });

    testWidgets('zero is rejected with a message', (tester) async {
      final values = await pumpField(tester);
      await tester.enterText(find.byType(TextField), '0.00');
      await tester.pump();
      expect(values.last, isNull);
      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    });

    testWidgets('empty yields null without an error', (tester) async {
      final values = await pumpField(tester, initialMinor: 500);
      expect(find.text('5.00'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(values.last, isNull);
      expect(find.textContaining('Enter'), findsNothing);
    });

    testWidgets('above Money.maxMinor is too large', (tester) async {
      final values = await pumpField(tester);
      await tester.enterText(find.byType(TextField), '999999999999999');
      await tester.pump();
      expect(values.last, isNull);
      expect(find.text('That amount is too large.'), findsOneWidget);
    });

    testWidgets('regroups the value when focus leaves', (tester) async {
      await pumpField(tester);
      await tester.enterText(find.byType(TextField), '1250.5');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(find.text('1,250.50'), findsOneWidget);
    });
  });

  group('MoneyInputFormatter', () {
    TextEditingValue apply(Currency currency, String from, String to) =>
        MoneyInputFormatter(currency).formatEditUpdate(
          TextEditingValue(text: from),
          TextEditingValue(text: to),
        );

    test('accepts digits, grouping and one point', () {
      expect(apply(Currency.inr, '', '1,000.25').text, '1,000.25');
    });

    test('rejects letters and a second point', () {
      expect(apply(Currency.inr, '12', '12a').text, '12');
      expect(apply(Currency.inr, '1.2', '1.2.').text, '1.2');
    });

    test('allows three decimals for KWD', () {
      final kwd = Currency.byCode('KWD');
      expect(apply(kwd, '', '1.250').text, '1.250');
      expect(apply(kwd, '1.250', '1.2501').text, '1.250');
    });
  });
}
