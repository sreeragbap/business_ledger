import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/receipt_scan/logic/receipt_scan_cubit/receipt_scan_cubit.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/logic/settlement_form_cubit/settlement_form_cubit.dart';
import 'package:business_ledger/features/transactions/logic/transaction_detail_cubit/transaction_detail_cubit.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:business_ledger/features/transactions/logic/transaction_list_cubit/transaction_list_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/settlement_sheet.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_detail_view.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_form_view.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';
import '../../support/stub_auth_repository.dart';
import '../../support/stub_business_repositories.dart';
import '../receipt_scan/receipt_fakes.dart';
import 'stub_transaction_repository.dart';
import 'transaction_fixtures.dart';

/// Renders the transaction screens' bodies over stub data under the real
/// theme. Cubits and streams are closed without awaiting: inside a widget
/// test's fake-async zone their done futures complete only on a later pump.
void main() {
  late StubAuthRepository auth;
  late StubBusinessRepository businesses;
  late StubMemberRepository members;
  late BusinessScopeCubit scope;
  late StubTransactionRepository repository;
  late FakeConnectivity connectivity;

  Future<void> selectAs(Role role) async {
    await scope.select('b1');
    businesses
        .business('b1')
        .add(
          Success(
            Business(
              id: 'b1',
              name: 'Rao Traders',
              settings: BusinessSettings(
                enabledStandardFieldKeys: [
                  for (final field in StandardField.values) field.key,
                ],
              ),
            ),
          ),
        );
    members.membership('b1').add(Success(Member(uid: 'u1', role: role)));
  }

  setUp(() {
    auth = StubAuthRepository(initialUser: const AppUser(uid: 'u1'));
    businesses = StubBusinessRepository();
    members = StubMemberRepository();
    scope = BusinessScopeCubit(businesses, members, auth);
    repository = StubTransactionRepository();
    connectivity = FakeConnectivity();
  });

  tearDown(() {
    unawaited(scope.close());
    unawaited(auth.dispose());
    unawaited(businesses.dispose());
    unawaited(members.dispose());
    unawaited(repository.dispose());
    unawaited(connectivity.dispose());
  });

  testWidgets('list: sections, overdue chip, tap and insert animation', (
    tester,
  ) async {
    final categories = StubCategoryRepository();
    final parties = StubPartyRepository();
    final projects = StubProjectRepository();
    final cubit = TransactionListCubit(
      repository,
      categories,
      parties,
      projects,
      debounce: Duration.zero,
      now: () => now,
    );
    final opened = <String>[];
    final created = <TransactionType>[];
    {
      await selectAs(Role.admin);
      await cubit.start('b1');
    }

    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: scope),
          BlocProvider.value(value: cubit),
        ],
        child: TransactionListView(
          onOpen: (tx) => opened.add(tx.id),
          onCreate: created.add,
        ),
      ),
    );
    repository.emitPage([
      confirmedSale(dueDate: '2026-10-05'),
      draftExpense(),
    ]);
    await _pumpFrames(tester);

    expect(find.text('Cement bags'), findsOneWidget);
    expect(find.text('October rent'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('+₹1,000.00'), findsOneWidget);
    expect(find.text('THURSDAY, 1 OCTOBER 2026'), findsOneWidget);

    await tester.tap(find.text('Cement bags'));
    expect(opened, ['t1']);
    await tester.tap(find.text('New transaction'));
    expect(created, [TransactionType.expense]);

    // A new entry animates in alongside the existing rows.
    repository.emitPage([
      confirmedSale(id: 't2'),
      confirmedSale(dueDate: '2026-10-05'),
      draftExpense(),
    ]);
    await _pumpFrames(tester);
    expect(find.text('Cement bags'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    unawaited(cubit.close());
    unawaited(categories.dispose());
    unawaited(parties.dispose());
    unawaited(projects.dispose());
  });

  testWidgets('list: empty state speaks to the filter', (tester) async {
    final categories = StubCategoryRepository();
    final parties = StubPartyRepository();
    final projects = StubProjectRepository();
    final cubit = TransactionListCubit(
      repository,
      categories,
      parties,
      projects,
      now: () => now,
    );
    {
      await selectAs(Role.viewer);
      await cubit.start('b1', filter: TransactionFilter.outstanding);
    }
    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: scope),
          BlocProvider.value(value: cubit),
        ],
        child: TransactionListView(onOpen: (_) {}, onCreate: (_) {}),
      ),
    );
    repository.emitPage(const []);
    await _pumpFrames(tester);
    expect(find.text('Nothing outstanding'), findsOneWidget);
    expect(find.text('New transaction'), findsNothing, reason: 'viewer');

    unawaited(cubit.close());
    unawaited(categories.dispose());
    unawaited(parties.dispose());
    unawaited(projects.dispose());
  });

  testWidgets('detail: queued actions are listed under an unchanged '
      'balance; money actions stay available offline', (tester) async {
    final fieldRepository = StubCustomFieldRepository();
    connectivity.isOnline = false;
    final cubit = TransactionDetailCubit(
      repository,
      fieldRepository,
      connectivity.service,
      now: () => now,
    );
    var reviews = 0;
    {
      repository.emitTransaction(
        confirmedSale(paid: 40000, status: PaymentStatus.partiallyPaid),
      );
      await cubit.start(
        businessId: 'b1',
        transactionId: 't1',
        role: Role.admin,
      );
    }
    await tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: TransactionDetailView(
          currency: Currency.inr,
          onEdit: (_) {},
          onOpenTransaction: (_) {},
          onRecordSettlement: (_) {},
          onDocuments: (_) {},
          onDuplicated: (_) {},
          onOpenSync: () => reviews++,
        ),
      ),
    );
    await _pumpFrames(tester);
    expect(find.text('Pending sync'), findsNothing);

    repository.queued.add([
      queuedEntry('r1', label: 'Payment ₹200.00 · Cement bags'),
      queuedEntry('r-other', transactionId: 't9', label: 'Not this one'),
    ]);
    await _pumpFrames(tester);
    // The chip in the header and the card under the balance.
    expect(find.text('Pending sync'), findsNWidgets(2));
    expect(
      find.text('Payment ₹200.00 · Cement bags — waiting to sync'),
      findsOneWidget,
    );
    expect(find.textContaining('Not this one'), findsNothing);
    expect(
      find.textContaining('Not in the balance above'),
      findsOneWidget,
    );
    // The server balance is untouched: still 40,000 of 100,000 paid.
    expect(find.text('Partially paid'), findsOneWidget);
    // Recording money stays possible, with the queueing explained.
    expect(find.text('Record payment'), findsOneWidget);
    expect(find.textContaining('applied when synced'), findsOneWidget);

    repository.queued.add([
      queuedEntry(
        'r1',
        label: 'Payment ₹200.00 · Cement bags',
        status: OutboxStatus.failed,
        error: const OutboxError(message: 'More than what is outstanding.'),
      ),
    ]);
    await _pumpFrames(tester);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(
      find.textContaining("couldn't be applied: More than what is"),
      findsOneWidget,
    );
    await tester.tap(find.text('Review'));
    expect(reviews, 1);
    expect(tester.takeException(), isNull);

    unawaited(cubit.close());
    unawaited(fieldRepository.dispose());
  });

  testWidgets('list: rows with queued actions carry a Pending sync badge', (
    tester,
  ) async {
    final categories = StubCategoryRepository();
    final parties = StubPartyRepository();
    final projects = StubProjectRepository();
    final cubit = TransactionListCubit(
      repository,
      categories,
      parties,
      projects,
      debounce: Duration.zero,
      now: () => now,
    );
    {
      await selectAs(Role.admin);
      await cubit.start('b1');
    }
    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: scope),
          BlocProvider.value(value: cubit),
        ],
        child: TransactionListView(onOpen: (_) {}, onCreate: (_) {}),
      ),
    );
    repository
      ..emitPage([confirmedSale(), draftExpense()])
      ..queued.add([queuedEntry('r1')]);
    await _pumpFrames(tester);
    expect(find.text('Pending sync'), findsOneWidget);
    expect(cubit.state.syncMarkOf('t1'), SyncMark.pending);
    expect(tester.takeException(), isNull);

    unawaited(cubit.close());
    unawaited(categories.dispose());
    unawaited(parties.dispose());
    unawaited(projects.dispose());
  });

  Widget detail(
    TransactionDetailCubit cubit, {
    List<SettlementKind>? recorded,
  }) => BlocProvider.value(
    value: cubit,
    child: TransactionDetailView(
      currency: Currency.inr,
      onEdit: (_) {},
      onOpenTransaction: (_) {},
      onRecordSettlement: (kind) => recorded?.add(kind),
      onDocuments: (_) {},
      onDuplicated: (_) {},
    ),
  );

  testWidgets('detail: balance labels cash vs recognised, record payment', (
    tester,
  ) async {
    final fieldRepository = StubCustomFieldRepository();
    final cubit = TransactionDetailCubit(
      repository,
      fieldRepository,
      connectivity.service,
      now: () => now,
    );
    final recorded = <SettlementKind>[];
    {
      repository.emitTransaction(
        confirmedSale(paid: 40000, status: PaymentStatus.partiallyPaid),
      );
      await cubit.start(
        businessId: 'b1',
        transactionId: 't1',
        role: Role.admin,
      );
    }
    await tester.pumpApp(detail(cubit, recorded: recorded));
    await _pumpFrames(tester);

    expect(find.text('Partially paid'), findsOneWidget);
    expect(find.textContaining('Cash received'), findsOneWidget);
    expect(
      find.textContaining('Outstanding — still to receive'),
      findsOneWidget,
    );
    expect(find.textContaining('Recognised income'), findsOneWidget);
    await tester.tap(find.text('Record payment'));
    expect(recorded, [SettlementKind.payment]);
    expect(tester.takeException(), isNull);

    unawaited(cubit.close());
    unawaited(fieldRepository.dispose());
  });

  testWidgets('detail: a cancelled entry is VOID and read-only', (
    tester,
  ) async {
    final fieldRepository = StubCustomFieldRepository();
    final cubit = TransactionDetailCubit(
      repository,
      fieldRepository,
      connectivity.service,
      now: () => now,
    );
    {
      repository.emitTransaction(cancelledSale());
      await cubit.start(
        businessId: 'b1',
        transactionId: 't1',
        role: Role.admin,
      );
    }
    await tester.pumpApp(detail(cubit));
    await _pumpFrames(tester);
    expect(find.textContaining('VOID'), findsOneWidget);
    expect(find.textContaining('Entered twice'), findsOneWidget);
    expect(find.text('Cancelled transactions are read-only.'), findsOneWidget);
    expect(find.text('Record payment'), findsNothing);

    unawaited(cubit.close());
    unawaited(fieldRepository.dispose());
  });

  testWidgets('form: type chips, live total, role-aware actions', (
    tester,
  ) async {
    final categories = StubCategoryRepository();
    final fieldRepository = StubCustomFieldRepository();
    final parties = StubPartyRepository();
    final projects = StubProjectRepository();
    final cubit = TransactionFormCubit(
      repository,
      categories,
      fieldRepository,
      parties,
      projects,
      connectivity.service,
      now: () => now,
    );
    {
      await cubit.start(
        businessId: 'b1',
        currency: Currency.inr,
        role: Role.admin,
        enabledFields: StandardField.values.toSet(),
      );
    }
    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider(
            create: (_) => ReceiptScanCubit(
              FakeReceiptScanner(),
              FakeReceiptAi(),
              connectivity.service,
            ),
          ),
        ],
        child: TransactionFormView(onDone: (_, _) {}),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('New transaction'), findsOneWidget);
    expect(find.text('Save draft'), findsOneWidget);
    expect(find.text('Save & confirm'), findsOneWidget);
    expect(find.text('Save, confirm & mark paid'), findsOneWidget);

    await tester.tap(find.text('Sale'));
    await _pumpFrames(tester);
    expect(cubit.state.type, TransactionType.sale);
    expect(find.text('Save, confirm & mark received'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '1250.5');
    await _pumpFrames(tester);
    expect(cubit.state.total, 125050);
    expect(find.text('₹1,250.50'), findsOneWidget);
    expect(tester.takeException(), isNull);

    unawaited(cubit.close());
    unawaited(categories.dispose());
    unawaited(fieldRepository.dispose());
    unawaited(parties.dispose());
    unawaited(projects.dispose());
  });

  testWidgets('settlement sheet: quick fill, preview, kinds explained', (
    tester,
  ) async {
    final tx = confirmedSale(paid: 40000, status: PaymentStatus.partiallyPaid);
    final cubit = SettlementFormCubit(repository, now: () => now);
    {
      repository.emitTransaction(tx);
      await cubit.start(businessId: 'b1', transaction: tx);
    }
    await tester.pumpApp(
      SingleChildScrollView(
        child: BlocProvider.value(
          value: cubit,
          child: const SettlementSheet(currency: Currency.inr),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Refund'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.text('After this'), findsNothing);

    await tester.tap(find.text('Full outstanding (₹600.00)'));
    await _pumpFrames(tester);
    expect(cubit.state.amountMinor, 60000);
    expect(find.text('After this'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);

    // More than outstanding is refused inline, before any call.
    cubit.setAmount(60001);
    await _pumpFrames(tester);
    expect(
      find.text('That is more than the outstanding balance.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    unawaited(cubit.close());
  });

  testWidgets('settlement sheet: a queued payment shrinks what is left and '
      'the preview says it includes pending actions', (tester) async {
    final tx = confirmedSale(paid: 40000, status: PaymentStatus.partiallyPaid);
    final cubit = SettlementFormCubit(repository, now: () => now);
    {
      repository.emitTransaction(tx);
      await cubit.start(
        businessId: 'b1',
        transaction: tx,
        queued: [
          queuedEntry(
            'q1',
            payload: {'kind': 'payment', 'amountMinor': 50000},
          ),
        ],
      );
    }
    await tester.pumpApp(
      SingleChildScrollView(
        child: BlocProvider.value(
          value: cubit,
          child: const SettlementSheet(currency: Currency.inr),
        ),
      ),
    );
    await _pumpFrames(tester);
    expect(find.text('Full outstanding (₹100.00)'), findsOneWidget);
    await tester.tap(find.text('Full outstanding (₹100.00)'));
    await _pumpFrames(tester);
    expect(cubit.state.amountMinor, 10000);
    expect(find.text('After this and pending actions'), findsOneWidget);
    // Server ₹400.00 paid → ₹1,000.00 once the queued ₹500.00 and this land.
    expect(find.text('₹400.00 → ₹1,000.00'), findsOneWidget);

    cubit.setAmount(10001);
    await _pumpFrames(tester);
    expect(
      find.text('That is more than the outstanding balance.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    unawaited(cubit.close());
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}
