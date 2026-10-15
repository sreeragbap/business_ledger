import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_switcher.dart';
import 'package:business_ledger/features/reports/logic/reports_cubit/reports_cubit.dart';
import 'package:business_ledger/features/reports/screens/reports_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Reports tab: [ReportsView] for the selected business, restarted
/// whenever the user switches business.
@RoutePage()
class ReportsScreen extends StatelessWidget implements AutoRouteWrapper {
  const ReportsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider<ReportsCubit>(
    create: (_) {
      final cubit = getIt<ReportsCubit>();
      final business = context.read<BusinessScopeCubit>().state.business;
      if (business != null) {
        unawaited(
          cubit.start(businessId: business.id, currency: business.currency),
        );
      }
      return cubit;
    },
    child: this,
  );

  @override
  Widget build(BuildContext context) =>
      BlocListener<BusinessScopeCubit, BusinessScopeState>(
        listenWhen: (previous, current) =>
            previous.business?.id != current.business?.id ||
            previous.business?.currency != current.business?.currency,
        listener: (context, state) {
          final business = state.business;
          if (business == null) return;
          unawaited(
            context.read<ReportsCubit>().start(
              businessId: business.id,
              currency: business.currency,
            ),
          );
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Reports'),
            actions: const [BusinessSwitcherButton()],
          ),
          body: const ReportsView(),
        ),
      );
}
