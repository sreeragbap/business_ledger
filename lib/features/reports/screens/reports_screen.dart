import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/features/home/widgets/placeholder_tab.dart';
import 'package:flutter/material.dart';

/// Placeholder until stage 8 (stats, receivables, payables).
@RoutePage()
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderTab(
    title: 'Reports',
    icon: Icons.insert_chart_outlined,
    emptyTitle: 'Nothing to report yet',
    emptyMessage:
        'Income, expenses and cash flow by day, week and month will show '
        'here once you confirm transactions.',
  );
}
