import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/documents/domain/models/document_action.dart';
import 'package:business_ledger/features/documents/logic/document_cubit/document_cubit.dart';
import 'package:business_ledger/features/documents/screens/document_preview_screen.dart';
import 'package:business_ledger/features/documents/widgets/document_actions_sheet.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/logic/settlement_form_cubit/settlement_form_cubit.dart';
import 'package:business_ledger/features/transactions/logic/transaction_detail_cubit/transaction_detail_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/settlement_sheet.dart';
import 'package:business_ledger/features/transactions/widgets/success_check.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One transaction: balance, settlements, documents and actions.
@RoutePage()
class TransactionDetailScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const TransactionDetailScreen({
    @PathParam('transactionId') required this.transactionId,
    super.key,
  });

  final String transactionId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final scope = context.read<BusinessScopeCubit>().state;
    final businessId = scope.businessId;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = getIt<TransactionDetailCubit>();
            if (businessId != null) {
              unawaited(
                cubit.start(
                  businessId: businessId,
                  transactionId: transactionId,
                  role: scope.role,
                  currency: scope.business?.currency ?? Currency.inr,
                ),
              );
            }
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = getIt<DocumentCubit>();
            if (businessId != null) {
              unawaited(cubit.watchTransaction(businessId, transactionId));
            }
            return cubit;
          },
        ),
      ],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.select<BusinessScopeCubit, Currency>(
      (cubit) => cubit.state.business?.currency ?? Currency.inr,
    );
    return BlocListener<BusinessScopeCubit, BusinessScopeState>(
      listenWhen: (p, c) => p.role != c.role,
      listener: (context, state) =>
          context.read<TransactionDetailCubit>().updateRole(state.role),
      child: TransactionDetailView(
        currency: currency,
        onEdit: (tx) => unawaited(
          context.router.push(TransactionFormRoute(transactionId: tx.id)),
        ),
        onOpenTransaction: (id) => unawaited(
          context.router.push(TransactionDetailRoute(transactionId: id)),
        ),
        onDuplicated: (id) => unawaited(
          context.router.push(TransactionFormRoute(transactionId: id)),
        ),
        onRecordSettlement: (kind) =>
            unawaited(_recordSettlement(context, kind, currency)),
        onDocuments: (tx) => unawaited(_documents(context, tx, currency)),
        onOpenSync: () => unawaited(context.router.push(const SyncRoute())),
      ),
    );
  }

  Future<void> _recordSettlement(
    BuildContext context,
    SettlementKind kind,
    Currency currency,
  ) async {
    final state = context.read<TransactionDetailCubit>().state;
    final tx = state.transaction;
    final businessId = state.businessId;
    if (tx == null || businessId == null) return;
    final cubit = getIt<SettlementFormCubit>();
    await cubit.start(
      businessId: businessId,
      transaction: tx,
      kind: kind,
      currency: currency,
      queued: state.queued,
    );
    if (!context.mounted) {
      await cubit.close();
      return;
    }
    final result = await showSettlementSheet(
      context: context,
      cubit: cubit,
      currency: currency,
      online: state.online,
    );
    final recorded = cubit.state.kind;
    final message = cubit.state.submitStatus.message;
    await cubit.close();
    if (result == null || !context.mounted) return;
    if (result.isQueued) {
      showAppSnackBar(context, message, kind: AppSnackBarKind.success);
    } else {
      showSuccessCheck(context, label: '${recorded.label} recorded');
    }
  }

  Future<void> _documents(
    BuildContext context,
    LedgerTransaction tx,
    Currency currency,
  ) async {
    final documents = context.read<DocumentCubit>();
    final detail = context.read<TransactionDetailCubit>().state;
    final businessId = detail.businessId;
    if (businessId == null) return;
    final action = await showDocumentActionsSheet(
      context: context,
      subject: DocumentSubject(
        businessId: businessId,
        transactionId: tx.id,
        type: tx.type,
        status: tx.status,
        currency: currency,
        payments: [
          for (final settlement in detail.settlements)
            DocumentPaymentRef(
              settlementId: settlement.id,
              kind: settlement.kind,
              amountMinor: settlement.amountMinor,
              date: settlement.date,
              voided: settlement.voided,
            ),
        ],
      ),
      issued: documents.state.documents,
      online: detail.online,
    );
    if (action == null || !context.mounted) return;
    final existing = action.existing;
    if (existing != null) {
      unawaited(documents.open(existing));
    } else {
      unawaited(
        documents.issue(
          businessId: businessId,
          transactionId: tx.id,
          type: action.type,
          settlementId: action.settlementId,
        ),
      );
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: documents,
          child: const DocumentPreviewScreen(),
        ),
      ),
    );
  }
}
