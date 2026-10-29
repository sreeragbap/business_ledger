import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/receipt_scan/logic/receipt_scan_cubit/receipt_scan_cubit.dart';
import 'package:business_ledger/features/receipt_scan/widgets/receipt_scan_button.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_form_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';
import '../../support/stub_business_repositories.dart';
import '../transactions/stub_transaction_repository.dart';
import '../transactions/transaction_fixtures.dart';
import 'receipt_fakes.dart';

void main() {
  late StubTransactionRepository repository;
  late StubCategoryRepository categoryRepository;
  late StubCustomFieldRepository fieldRepository;
  late StubPartyRepository parties;
  late StubProjectRepository projects;
  late FakeConnectivity connectivity;
  late FakeReceiptScanner scanner;
  late FakeReceiptAi ai;
  late TransactionFormCubit form;

  setUp(() {
    repository = StubTransactionRepository();
    categoryRepository = StubCategoryRepository();
    fieldRepository = StubCustomFieldRepository();
    parties = StubPartyRepository();
    projects = StubProjectRepository();
    connectivity = FakeConnectivity();
    scanner = FakeReceiptScanner();
    ai = FakeReceiptAi()
      ..answer = const Success(
        ReceiptScan(
          totalMinor: 95500,
          date: '2026-10-24',
          merchant: 'Reliance Fresh',
          categoryId: 'c-rent',
          description: 'Groceries',
          reader: ReceiptReader.ai,
        ),
      );
  });

  tearDown(() async {
    await repository.dispose();
    await categoryRepository.dispose();
    await fieldRepository.dispose();
    await parties.dispose();
    await projects.dispose();
    await connectivity.dispose();
  });

  Future<void> openForm(WidgetTester tester) async {
    form = TransactionFormCubit(
      repository,
      categoryRepository,
      fieldRepository,
      parties,
      projects,
      connectivity.service,
      nextRequestId: requestIds(),
      now: () => now,
    );
    await form.start(
      businessId: 'b1',
      currency: Currency.inr,
      role: Role.admin,
      enabledFields: StandardField.values.toSet(),
      initialType: TransactionType.expense,
    );
    categoryRepository.categories.add(const Success(categories));
    fieldRepository.fields.add(const Success(fields));
    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: form),
          BlocProvider(
            create: (_) {
              final cubit = ReceiptScanCubit(
                scanner,
                ai,
                connectivity.service,
                now: () => now,
                minReading: Duration.zero,
              );
              unawaited(cubit.init());
              return cubit;
            },
          ),
        ],
        child: TransactionFormView(onDone: (_, _) {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scanFromPhotos(WidgetTester tester) async {
    await tester.tap(find.byType(ReceiptScanButton));
    await tester.pumpAndSettle();
    expect(find.text('Scan a receipt'), findsOneWidget);
    await tester.tap(find.text('Choose a photo'));
    await tester.pumpAndSettle();
  }

  testWidgets('scanning fills the form at once', (
    tester,
  ) async {
    await openForm(tester);
    final today = form.state.draft!.date;
    // A form that was not scanned has no receipt date field.
    expect(find.text('Receipt date', skipOffstage: false), findsNothing);
    await scanFromPhotos(tester);

    expect(scanner.sources, [ReceiptSource.photos]);
    final draft = form.state.draft!;
    expect(draft.totalMinor, 95500);
    expect(draft.date, today);
    expect(draft.receiptDate, '2026-10-24');
    // Shown in "When" only because a scan filled it.
    await tester.scrollUntilVisible(
      find.text('Receipt date'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Receipt date'), findsOneWidget);
    expect(draft.categoryId, 'c-rent');
    // The shop is new: it becomes a supplier rather than description text.
    expect(draft.partyName, 'Reliance Fresh');
    expect(draft.description, 'Groceries');
    expect(
      find.textContaining('added Reliance Fresh as a supplier'),
      findsOneWidget,
    );
    expect(
      find.textContaining('from the receipt with AI'),
      findsOneWidget,
    );
    // The field itself shows the new text (rebuilt with the fill).
    final description = find.text('Groceries');
    await tester.scrollUntilVisible(
      description,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(description, findsOneWidget);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('a receipt with nothing readable says so', (tester) async {
    scanner.recognised = Success(ocrRows(['~~~']));
    ai.answer = const Success(ReceiptScan(reader: ReceiptReader.ai));
    await openForm(tester);
    await scanFromPhotos(tester);
    expect(find.textContaining("Couldn't find any details"), findsOneWidget);
    expect(form.state.formRevision, 0);
  });

  testWidgets('a scanner error shows its message', (tester) async {
    scanner.captured = const Failure(scanFailure);
    await openForm(tester);
    await scanFromPhotos(tester);
    expect(find.text(scanFailure.message), findsOneWidget);
  });

  testWidgets('the camera option is disabled where there is no camera', (
    tester,
  ) async {
    scanner.camera = false;
    await openForm(tester);
    await tester.tap(find.byType(ReceiptScanButton));
    await tester.pumpAndSettle();
    expect(find.text('Not available on this device'), findsOneWidget);
    await tester.tap(find.text('Scan with camera'));
    await tester.pumpAndSettle();
    expect(scanner.sources, isEmpty);
  });
}
