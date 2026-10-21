import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The signed-in shell: four tabs under a bottom navigation bar. Each tab
/// keeps its own state while another is showing.
///
/// Everything inside works on the current business, so the shell watches
/// `BusinessScopeCubit`: if the selection is dropped (the user left or was
/// removed, the business is gone) it hands over to the business picker.
/// Switching business replaces the whole shell (see `openBusiness`), so no
/// tab ever shows one business's data under another's name.
@RoutePage()
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  static const List<_Tab> _tabs = [
    _Tab('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard),
    _Tab('Transactions', Icons.receipt_long_outlined, Icons.receipt_long),
    _Tab('Reports', Icons.insert_chart_outlined, Icons.insert_chart),
    _Tab('Settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    // Reached without the splash (a restored route, say): resolve now.
    final scope = context.read<BusinessScopeCubit>();
    if (scope.state.status == ScopeStatus.initial) {
      unawaited(scope.restore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessScopeCubit, BusinessScopeState>(
      listenWhen: (previous, current) =>
          previous.status != ScopeStatus.none &&
          current.status == ScopeStatus.none,
      listener: (context, _) => unawaited(
        context.router.root.replaceAll([const BusinessPickerRoute()]),
      ),
      child: AutoTabsRouter(
        routes: const [
          DashboardRoute(),
          TransactionsRoute(),
          ReportsRoute(),
          SettingsRoute(),
        ],
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        transitionBuilder: (context, child, animation) =>
            FadeTransition(opacity: animation, child: child),
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          return Scaffold(
            body: child,
            bottomNavigationBar: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.colors.divider)),
              ),
              child: NavigationBar(
                selectedIndex: tabsRouter.activeIndex,
                onDestinationSelected: tabsRouter.setActiveIndex,
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: tab.label,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
