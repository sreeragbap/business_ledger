import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_loader.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/logic/business_list_cubit/business_list_cubit.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_avatar.dart';
import 'package:business_ledger/features/business/widgets/business_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Makes [businessId] current and opens the home shell on it, discarding
/// whatever was showing for the previous business.
///
/// Reads what it needs from [context] before the first await, so it is safe
/// to call right after popping the sheet [context] belongs to.
Future<void> openBusiness(BuildContext context, String businessId) async {
  final router = context.router.root;
  final scope = context.read<BusinessScopeCubit>();
  await scope.select(businessId);
  // Not updating the existing shell: every tab starts over on the new
  // business rather than keeping the previous one's state.
  await router.replaceAll([
    const HomeShellRoute(),
  ], updateExistingRoutes: false);
}

/// The current business's name as a tappable chip, for app bars. Opens the
/// quick switcher.
class BusinessSwitcherButton extends StatelessWidget {
  const BusinessSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final business = context.select<BusinessScopeCubit, Business?>(
      (cubit) => cubit.state.business,
    );
    if (business == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Current business ${business.name}. Switch business',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.chip,
        onTap: () => unawaited(showBusinessSwitcher(context)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 200.w),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xs.w,
            AppSpacing.xs.h,
            AppSpacing.sm.w,
            AppSpacing.xs.h,
          ),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadius.chip,
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BusinessAvatar(business: business, size: 26),
              SizedBox(width: AppSpacing.sm.w),
              Flexible(
                child: Text(
                  business.name,
                  style: textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.unfold_more_rounded, size: 18.r),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showBusinessSwitcher(BuildContext context) =>
    showAppBottomSheet<void>(
      context: context,
      title: 'Switch business',
      child: const _BusinessSwitcherSheet(),
    );

class _BusinessSwitcherSheet extends StatelessWidget {
  const _BusinessSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.uid;
    return BlocProvider<BusinessListCubit>(
      create: (_) {
        final cubit = getIt<BusinessListCubit>();
        if (uid != null) unawaited(cubit.watch(uid));
        return cubit;
      },
      child: const _SwitcherBody(),
    );
  }
}

class _SwitcherBody extends StatelessWidget {
  const _SwitcherBody();

  @override
  Widget build(BuildContext context) {
    final currentId = context.select<BusinessScopeCubit, String?>(
      (cubit) => cubit.state.businessId,
    );
    return BlocBuilder<BusinessListCubit, BusinessListState>(
      builder: (context, state) {
        final businesses = state.businesses
            ?.where((business) => !business.archived)
            .toList();
        final Widget list;
        if (businesses == null) {
          list = state.loadStatus.isFailure
              ? AppErrorState(message: state.loadStatus.message)
              : SizedBox(height: 120.h, child: const AppLoader());
        } else {
          list = Column(
            children: [
              for (final business in businesses) ...[
                BusinessTile(
                  business: business,
                  selected: business.id == currentId,
                  onTap: () {
                    if (business.id != currentId) {
                      unawaited(openBusiness(context, business.id));
                    }
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(height: AppSpacing.sm.h),
              ],
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              alignment: Alignment.topCenter,
              child: list,
            ),
            SizedBox(height: AppSpacing.md.h),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'All businesses',
                    icon: Icons.storefront_outlined,
                    onPressed: () {
                      final router = context.router.root;
                      Navigator.of(context).pop();
                      unawaited(router.push(const BusinessPickerRoute()));
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: AppButton(
                    label: 'New',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      final router = context.router.root;
                      Navigator.of(context).pop();
                      unawaited(router.push(const CreateBusinessRoute()));
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
