import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// The signed-in shell: four tabs under a bottom navigation bar. Each tab
/// keeps its own state while another is showing.
@RoutePage()
class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  static const List<_Tab> _tabs = [
    _Tab('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard),
    _Tab('Transactions', Icons.receipt_long_outlined, Icons.receipt_long),
    _Tab('Reports', Icons.insert_chart_outlined, Icons.insert_chart),
    _Tab('Settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
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
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
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
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
