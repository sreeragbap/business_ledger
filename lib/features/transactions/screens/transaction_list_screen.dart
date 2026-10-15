import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/logic/transaction_list_cubit/transaction_list_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The transactions list pushed with a preset filter (the dashboard's "See
/// all" for pending and overdue).
@RoutePage()
class TransactionListScreen extends StatelessWidget
    implements AutoRouteWrapper {
  const TransactionListScreen({
    this.initialFilter = const TransactionFilter(),
    this.title = 'Transactions',
    super.key,
  });

  final TransactionFilter initialFilter;
  final String title;

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = getIt<TransactionListCubit>();
      final businessId = context.read<BusinessScopeCubit>().state.businessId;
      if (businessId != null) {
        unawaited(cubit.start(businessId, filter: initialFilter));
      }
      return cubit;
    },
    child: this,
  );

  @override
  Widget build(BuildContext context) => TransactionListView(
    title: title,
    onOpen: (tx) => unawaited(
      context.router.push(TransactionDetailRoute(transactionId: tx.id)),
    ),
    onCreate: (type) =>
        unawaited(context.router.push(TransactionFormRoute(initialType: type))),
  );
}
