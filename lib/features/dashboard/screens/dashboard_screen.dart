import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Placeholder until stage 8. Shows the layout the real dashboard will fill:
/// cash and income/expense kept apart, as ARCHITECTURE §6 asks.
@RoutePage()
class DashboardScreen extends StatelessWidget implements AutoRouteWrapper {
  const DashboardScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) =>
      BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>(), child: this);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = context.select<AuthCubit, String>(
      (cubit) => cubit.state.user?.greetingName ?? 'there',
    );
    const currency = Currency.inr;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal.w,
            vertical: AppSpacing.lg.h,
          ),
          children: [
            Text('Hello, $name', style: textTheme.headlineMedium),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              'Here is where your business stands.',
              style: textTheme.bodyMedium,
            ),
            SizedBox(height: AppSpacing.xxl.h),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: 'Cash in',
                    value: Money.format(0, currency),
                    colour: AppColors.income,
                    icon: Icons.south_west_rounded,
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: _Figure(
                    label: 'Cash out',
                    value: Money.format(0, currency),
                    colour: AppColors.expense,
                    icon: Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xxl.h),
            AppCard(
              child: AppEmptyState(
                icon: Icons.storefront_outlined,
                title: 'No business selected',
                message: 'Create or pick a business to start recording.',
                action: AppButton(
                  label: 'Choose a business',
                  expand: false,
                  onPressed: () => unawaited(
                    context.router.push(const BusinessPickerRoute()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.colour,
    required this.icon,
  });

  final String label;
  final String value;
  final Color colour;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xs.r),
                decoration: BoxDecoration(
                  color: AppColors.tint(colour),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14.r, color: colour),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Text(label, style: textTheme.labelMedium),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            value,
            style: AppTextStyles.tabular(textTheme.titleLarge!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
