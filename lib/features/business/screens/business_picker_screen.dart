import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';

/// Placeholder until stage 6 (create, switch and manage businesses).
@RoutePage()
class BusinessPickerScreen extends StatelessWidget {
  const BusinessPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your businesses')),
      body: AppEmptyState(
        icon: Icons.storefront_outlined,
        title: 'No businesses yet',
        message:
            'Create a business to keep its books, or ask an owner to add you '
            'to theirs.',
        action: AppButton(
          label: 'Create a business',
          icon: Icons.add_rounded,
          expand: false,
          onPressed: () => showAppSnackBar(
            context,
            'Creating businesses arrives in the next update.',
          ),
        ),
      ),
    );
  }
}
