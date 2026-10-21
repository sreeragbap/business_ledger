import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_form_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';
import '../../support/stub_business_repositories.dart';
import 'stub_transaction_repository.dart';
import 'transaction_fixtures.dart';

void main() {
  late StubTransactionRepository repository;
  late StubCategoryRepository categoryRepository;
  late StubCustomFieldRepository fieldRepository;
  late StubPartyRepository parties;
  late StubProjectRepository projects;
  late FakeConnectivity connectivity;
  late TransactionFormCubit cubit;

  setUp(() {
    repository = StubTransactionRepository();
    categoryRepository = StubCategoryRepository();
    fieldRepository = StubCustomFieldRepository();
    parties = StubPartyRepository();
    projects = StubProjectRepository();
    connectivity = FakeConnectivity();
  });

  tearDown(() async {
    await repository.dispose();
    await categoryRepository.dispose();
    await fieldRepository.dispose();
    await parties.dispose();
    await projects.dispose();
    await connectivity.dispose();
  });

  /// A home page with the form pushed on top, like the real app.
  Future<void> openForm(WidgetTester tester) async {
    cubit = TransactionFormCubit(
      repository,
      categoryRepository,
      fieldRepository,
      parties,
      projects,
      connectivity.service,
      nextRequestId: requestIds(),
      now: () => now,
    );
    await cubit.start(
      businessId: 'b1',
      currency: Currency.inr,
      role: Role.admin,
      enabledFields: StandardField.values.toSet(),
      initialType: TransactionType.expense,
    );
    categoryRepository.categories.add(const Success(categories));
    fieldRepository.fields.add(const Success(fields));
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: TransactionFormView(onDone: (_, _) {}),
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

  testWidgets('an untouched form closes without asking', (tester) async {
    await openForm(tester);
    await pressBack(tester);
    expect(find.text('Discard this transaction?'), findsNothing);
    expect(find.byType(TransactionFormView), findsNothing);
  });

  testWidgets('typed changes ask first; Keep editing stays, Discard leaves', (
    tester,
  ) async {
    await openForm(tester);
    final description = find.descendant(
      of: find.widgetWithText(AppTextField, 'Description'),
      matching: find.byType(EditableText),
    );
    await tester.scrollUntilVisible(
      description,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(description, 'Diesel');
    await tester.pump();
    expect(cubit.state.hasUnsavedChanges, isTrue);

    await pressBack(tester);
    expect(find.text('Discard this transaction?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormView), findsOneWidget);

    await pressBack(tester);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormView), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
