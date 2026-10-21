import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/logic/create_business_cubit/create_business_cubit.dart';
import 'package:business_ledger/features/business/screens/create_business_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';
import '../../support/stub_business_repositories.dart';

void main() {
  /// A home page with the screen pushed on top, like the real app.
  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => CreateBusinessCubit(StubBusinessRepository()),
                child: const CreateBusinessScreen(),
              ),
            ),
          ),
          child: const Text('home'),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(AppTextField, label),
    matching: find.byType(EditableText),
  );

  testWidgets('an untouched form closes without asking', (tester) async {
    await openScreen(tester);
    await pressBack(tester);
    expect(find.text('Discard this business?'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a typed name asks; Keep editing stays, Discard leaves', (
    tester,
  ) async {
    await openScreen(tester);
    await tester.enterText(field('Business name'), 'Rao Constructions');
    await tester.pump();

    await pressBack(tester);
    expect(find.text('Discard this business?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateBusinessScreen), findsOneWidget);

    await pressBack(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a changed choice counts too', (tester) async {
    await openScreen(tester);
    final other = Currency.supported.firstWhere((c) => c != Currency.inr);
    await tester.tap(find.textContaining(other.code));
    await tester.pump();

    await pressBack(tester);
    expect(find.text('Discard this business?'), findsOneWidget);
  });
}
