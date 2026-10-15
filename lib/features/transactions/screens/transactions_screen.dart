import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_switcher.dart';
import 'package:business_ledger/features/transactions/logic/transaction_list_cubit/transaction_list_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Transactions tab.
@RoutePage()
class TransactionsScreen extends StatelessWidget implements AutoRouteWrapper {
  const TransactionsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = getIt<TransactionListCubit>();
      final businessId = context.read<BusinessScopeCubit>().state.businessId;
      if (businessId != null) unawaited(cubit.start(businessId));
      return cubit;
    },
    child: this,
  );

  @override
  Widget build(BuildContext context) {
    // Only the visible tab may own hero tags: the shell keeps every tab
    // alive in the same route.
    final active =
        context.watchTabsRouter.current.name == TransactionsRoute.name;
    return BlocListener<BusinessScopeCubit, BusinessScopeState>(
      listenWhen: (p, c) => p.businessId != c.businessId,
      listener: (context, state) {
        final businessId = state.businessId;
        if (businessId != null) {
          unawaited(context.read<TransactionListCubit>().start(businessId));
        }
      },
      child: TransactionListView(
        heroEnabled: active,
        actions: const [BusinessSwitcherButton()],
        onOpen: (tx) => unawaited(
          context.router.push(TransactionDetailRoute(transactionId: tx.id)),
        ),
        onCreate: (type) => unawaited(
          context.router.push(TransactionFormRoute(initialType: type)),
        ),
      ),
    );
  }
}
