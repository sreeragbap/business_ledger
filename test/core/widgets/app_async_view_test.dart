import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/widgets/app_async_view.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_loader.dart';
import 'package:business_ledger/core/widgets/app_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';

void main() {
  group('AppAsyncView', () {
    Widget view(Status status, List<String>? data, {VoidCallback? retry}) =>
        AppAsyncView<List<String>>(
          status: status,
          data: data,
          isEmpty: (items) => items.isEmpty,
          onRetry: retry,
          builder: (_, items) => Text(items.join(',')),
        );

    testWidgets('first load shows the loader', (tester) async {
      await tester.pumpApp(view(const Status.loading(), null));
      expect(find.byType(AppLoader), findsOneWidget);
    });

    testWidgets('first-load failure shows the error with retry', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpApp(
        view(const Status.failure('No signal'), null, retry: () => retried++),
      );
      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('No signal'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });

    testWidgets('data stays on screen while reloading', (tester) async {
      await tester.pumpApp(view(const Status.loading(), ['a', 'b']));
      expect(find.text('a,b'), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('empty data shows the empty state', (tester) async {
      await tester.pumpApp(view(const Status.success(), []));
      expect(find.text('Nothing here yet'), findsOneWidget);
    });
  });

  group('AppStatusChip', () {
    testWidgets('overdue wins over the stored payment status', (tester) async {
      await tester.pumpApp(
        AppStatusChip.payment(PaymentStatus.partiallyPaid, overdue: true),
      );
      expect(find.text('Overdue'), findsOneWidget);
    });

    test('paid is the income colour, cancelled the error colour', () {
      expect(AppStatusChip.paymentColor(PaymentStatus.paid), AppColors.income);
      expect(
        AppStatusChip.transactionColor(TransactionStatus.cancelled),
        AppColors.error,
      );
    });
  });
}
