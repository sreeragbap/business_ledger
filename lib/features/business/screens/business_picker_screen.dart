import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_async_view.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_fade_in.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/logic/business_list_cubit/business_list_cubit.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_switcher.dart';
import 'package:business_ledger/features/business/widgets/business_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Every business the user belongs to. The landing screen when none is
/// selected (first launch, or after losing access), and reachable from
/// settings and the quick switcher to change business or create one.
@RoutePage()
class BusinessPickerScreen extends StatelessWidget implements AutoRouteWrapper {
  const BusinessPickerScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.uid;
    return BlocProvider<BusinessListCubit>(
      create: (_) {
        final cubit = getIt<BusinessListCubit>();
        if (uid != null) unawaited(cubit.watch(uid));
        return cubit;
      },
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = context.router.canPop();
    final scope = context.watch<BusinessScopeCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your businesses'),
        titleSpacing: canPop ? null : AppSpacing.screenHorizontal.w,
        actions: [
          BlocBuilder<BusinessListCubit, BusinessListState>(
            buildWhen: (p, c) =>
                p.archivedCount != c.archivedCount ||
                p.showArchived != c.showArchived,
            builder: (context, state) => state.archivedCount == 0
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: state.showArchived
                        ? 'Hide archived'
                        : 'Show archived',
                    icon: Icon(
                      state.showArchived
                          ? Icons.inventory_2_rounded
                          : Icons.inventory_2_outlined,
                    ),
                    onPressed: context.read<BusinessListCubit>().toggleArchived,
                  ),
          ),
          if (!canPop)
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => unawaited(_signOut(context)),
            ),
        ],
      ),
      floatingActionButton:
          BlocSelector<BusinessListCubit, BusinessListState, bool>(
            selector: (state) => state.visible?.isNotEmpty ?? false,
            builder: (context, hasAny) => hasAny
                ? FloatingActionButton.extended(
                    onPressed: () => unawaited(
                      context.router.push(const CreateBusinessRoute()),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New business'),
                  )
                : const SizedBox.shrink(),
          ),
      body: BlocBuilder<BusinessListCubit, BusinessListState>(
        builder: (context, state) => AppAsyncView<List<Business>>(
          status: state.loadStatus,
          data: state.visible,
          isEmpty: (items) => items.isEmpty,
          loading: const AppListSkeleton(rows: 3),
          onRetry: () {
            final uid = context.read<AuthCubit>().state.user?.uid;
            if (uid != null) {
              unawaited(context.read<BusinessListCubit>().watch(uid));
            }
          },
          empty: AppEmptyState(
            icon: Icons.storefront_outlined,
            title: state.archivedCount > 0 && !state.showArchived
                ? 'No active businesses'
                : 'No businesses yet',
            message:
                'Create a business to keep its books, or ask an owner to add '
                'you to theirs with the email you signed in with.',
            action: AppButton(
              label: 'Create a business',
              icon: Icons.add_rounded,
              expand: false,
              onPressed: () =>
                  unawaited(context.router.push(const CreateBusinessRoute())),
            ),
          ),
          builder: (context, businesses) => ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal.w,
              AppSpacing.sm.h,
              AppSpacing.screenHorizontal.w,
              96.h,
            ),
            children: [
              if (scope.lostMessage != null) ...[
                _Notice(message: scope.lostMessage!),
                SizedBox(height: AppSpacing.lg.h),
              ],
              for (final (index, business) in businesses.indexed) ...[
                AppFadeIn(
                  delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                  child: BusinessTile(
                    business: business,
                    selected:
                        business.id == scope.businessId &&
                        scope.status != ScopeStatus.none,
                    onTap: () => unawaited(openBusiness(context, business.id)),
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Sign out?',
      message: 'You can sign back in at any time.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed) await auth.signOut();
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.tint(context.colors.warning),
      borderColor: context.colors.warning.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.colors.warning,
            size: 20.r,
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Text(
              message,
              style:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
