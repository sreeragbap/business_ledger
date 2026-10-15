import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_switcher.dart';
import 'package:business_ledger/features/reports/logic/dashboard_cubit/dashboard_cubit.dart';
import 'package:business_ledger/features/reports/screens/dashboard_view.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The Dashboard tab: [DashboardView] for the selected business, restarted
/// whenever the user switches business.
@RoutePage()
class DashboardScreen extends StatelessWidget implements AutoRouteWrapper {
  const DashboardScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
      BlocProvider<DashboardCubit>(
        create: (_) {
          final cubit = getIt<DashboardCubit>();
          final business = context.read<BusinessScopeCubit>().state.business;
          if (business != null) {
            unawaited(
              cubit.start(businessId: business.id, currency: business.currency),
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
    final hasBusiness = context.select<BusinessScopeCubit, bool>(
      (cubit) => cubit.state.business != null,
    );

    return BlocListener<BusinessScopeCubit, BusinessScopeState>(
      listenWhen: (previous, current) =>
          previous.business?.id != current.business?.id ||
          previous.business?.currency != current.business?.currency,
      listener: (context, state) {
        final business = state.business;
        if (business == null) return;
        unawaited(
          context.read<DashboardCubit>().start(
            businessId: business.id,
            currency: business.currency,
          ),
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: hasBusiness
              ? DashboardView(
                  header: const _Header(),
                  onTransactionTap: (row) => unawaited(
                    context.router.push(
                      TransactionDetailRoute(transactionId: row.id),
                    ),
                  ),
                  onSeeAllPending: () => unawaited(
                    context.router.push(
                      TransactionListRoute(
                        initialFilter: TransactionFilter.outstanding,
                        title: 'Pending & overdue',
                      ),
                    ),
                  ),
                  // The Transactions tab: unfiltered, newest first.
                  onSeeAllRecent: () => unawaited(
                    context.tabsRouter.navigate(const TransactionsRoute()),
                  ),
                )
              : const _NoBusiness(),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = context.select<AuthCubit, String>(
      (cubit) => cubit.state.user?.greetingName ?? 'there',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hello, $name',
                style: textTheme.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            const BusinessSwitcherButton(),
          ],
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          'Here is where your business stands.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _NoBusiness extends StatelessWidget {
  const _NoBusiness();

  @override
  Widget build(BuildContext context) => Center(
    child: AppEmptyState(
      icon: Icons.storefront_outlined,
      title: 'No business selected',
      message: 'Create or pick a business to start recording.',
      action: AppButton(
        label: 'Choose a business',
        expand: false,
        onPressed: () =>
            unawaited(context.router.push(const BusinessPickerRoute())),
      ),
    ),
  );
}
