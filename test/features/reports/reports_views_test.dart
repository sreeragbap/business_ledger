import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/reports/logic/dashboard_cubit/dashboard_cubit.dart';
import 'package:business_ledger/features/reports/logic/reports_cubit/reports_cubit.dart';
import 'package:business_ledger/features/reports/screens/dashboard_view.dart';
import 'package:business_ledger/features/reports/screens/reports_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';
import 'reports_fixtures.dart';
import 'stub_reports_repository.dart';

void main() {
  late StubReportsRepository repository;

  setUp(() => repository = StubReportsRepository());
  tearDown(() => repository.dispose());

  testWidgets('DashboardView labels income, cash and outstanding apart', (
    tester,
  ) async {
    final cubit = DashboardCubit(repository);
    addTearDown(cubit.close);
    await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
    repository.stats.add(Success(octoberDays));
    repository.open.add(const Success([overdueSale]));
    repository.recent.add(const Success([]));

    await tester.pumpApp(
      BlocProvider.value(value: cubit, child: const DashboardView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Income (confirmed)'), findsOneWidget);
    expect(find.text('Cash received'), findsOneWidget);
    expect(find.text('Outstanding — not yet received'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '₹1,200.00',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Pending & overdue'),
      300,
      scrollable: _mainList,
    );
    expect(find.text('1 overdue · earliest due first'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReportsView renders charts and breakdowns', (tester) async {
    final cubit = ReportsCubit(repository);
    addTearDown(cubit.close);
    await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
    repository.stats.add(Success(octoberDays));

    await tester.pumpApp(
      BlocProvider.value(value: cubit, child: const ReportsView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Income vs expenses'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Income by category'),
      300,
      scrollable: _mainList,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sales'), findsWidgets);

    await tester.tap(find.text('Sales').first);
    await tester.pumpAndSettle();
    expect(cubit.state.scope?.label, 'Sales');
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReportsView shows an error with retry on first-load failure', (
    tester,
  ) async {
    final cubit = ReportsCubit(repository);
    addTearDown(cubit.close);
    await cubit.start(businessId: 'b1', currency: Currency.inr, now: now);
    repository.stats.add(const Failure(AppException.offline()));
    await tester.pumpApp(
      BlocProvider.value(value: cubit, child: const ReportsView()),
    );
    await tester.pumpAndSettle();
    expect(find.text(const AppException.offline().message), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

/// The vertical list, not the horizontal chip rows.
final Finder _mainList = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;
