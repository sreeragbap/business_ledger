import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/receipt_scan/logic/receipt_scan_cubit/receipt_scan_cubit.dart';
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/success_check.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_form_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Create a transaction ([initialType]) or edit one ([transactionId]).
@RoutePage()
class TransactionFormScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const TransactionFormScreen({
    this.transactionId,
    this.initialType,
    super.key,
  });

  final String? transactionId;
  final TransactionType? initialType;

  @override
  Widget wrappedRoute(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) {
          final scanner = getIt<ReceiptScanCubit>();
          unawaited(scanner.init());
          return scanner;
        },
      ),
      BlocProvider(
        create: (_) {
          final cubit = getIt<TransactionFormCubit>();
          final scope = context.read<BusinessScopeCubit>().state;
          final business = scope.business;
          if (business != null) {
            unawaited(
              cubit.start(
                businessId: business.id,
                currency: business.currency,
                role: scope.role,
                enabledFields: business.settings.enabledStandardFields,
                transactionId: transactionId,
                initialType: initialType,
              ),
            );
          }
          return cubit;
        },
      ),
    ],
    child: this,
  );

  @override
  Widget build(BuildContext context) {
    return TransactionFormView(
      onDone: (outcome, id) {
        final router = context.router;
        final editing = transactionId != null;
        switch (outcome) {
          case TransactionFormOutcome.savedDraft:
            showAppSnackBar(
              context,
              context.read<TransactionFormCubit>().state.saveStatus.message,
              kind: AppSnackBarKind.success,
            );
            unawaited(router.maybePop());
          case TransactionFormOutcome.confirmed ||
              TransactionFormOutcome.confirmedPaid:
            showSuccessCheck(
              context,
              label: outcome == TransactionFormOutcome.confirmedPaid
                  ? 'Confirmed & paid'
                  : 'Confirmed',
            );
            unawaited(
              editing
                  ? router.maybePop()
                  : router.replace(TransactionDetailRoute(transactionId: id)),
            );
          case TransactionFormOutcome.queued:
            showAppSnackBar(
              context,
              context.read<TransactionFormCubit>().state.saveStatus.message,
              kind: AppSnackBarKind.success,
            );
            unawaited(
              editing
                  ? router.maybePop()
                  : router.replace(TransactionDetailRoute(transactionId: id)),
            );
          case TransactionFormOutcome.edited:
            showAppSnackBar(
              context,
              context.read<TransactionFormCubit>().state.saveStatus.message,
              kind: AppSnackBarKind.success,
            );
            unawaited(router.maybePop());
        }
      },
    );
  }
}
