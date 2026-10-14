import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/features/home/widgets/placeholder_tab.dart';
import 'package:flutter/material.dart';

/// Placeholder until stage 7 (drafts, confirm, search).
@RoutePage()
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderTab(
    title: 'Transactions',
    icon: Icons.receipt_long_outlined,
    emptyTitle: 'No transactions yet',
    emptyMessage:
        'Sales, purchases, income and expenses you record will appear here.',
  );
}
