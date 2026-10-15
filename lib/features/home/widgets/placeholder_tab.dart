import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/features/business/widgets/business_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A titled tab body with an empty state, used by the tabs whose real
/// content arrives in later stages. The app bar carries the business
/// switcher, as every tab's does.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.icon,
    this.action,
    super.key,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        titleSpacing: AppSpacing.screenHorizontal.w,
        actions: [
          const BusinessSwitcherButton(),
          SizedBox(width: AppSpacing.screenHorizontal.w),
        ],
      ),
      body: AppEmptyState(
        icon: icon,
        title: emptyTitle,
        message: emptyMessage,
        action: action,
      ),
    );
  }
}
