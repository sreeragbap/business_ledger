import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/app_lock/logic/app_lock_cubit/app_lock_cubit.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/widgets/business_avatar.dart';
import 'package:business_ledger/features/business/widgets/business_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The settings hub: the current business and everything configured per
/// business (details, members, categories, fields, parties, projects),
/// then account and security. Every role can open every page; what they
/// may change is decided on each page by their role.
@RoutePage()
class SettingsScreen extends StatelessWidget implements AutoRouteWrapper {
  const SettingsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
      BlocProvider<AppLockCubit>.value(value: getIt<AppLockCubit>()),
    ],
    child: this,
  );

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, AppUser?>(
      (cubit) => cubit.state.user,
    );

    return BlocListener<AppLockCubit, AppLockState>(
      listenWhen: (p, c) => p.toggleStatus != c.toggleStatus,
      listener: (context, state) {
        if (state.toggleStatus.isFailure) {
          showAppSnackBar(
            context,
            state.toggleStatus.message,
            kind: AppSnackBarKind.error,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          titleSpacing: AppSpacing.screenHorizontal.w,
          actions: [
            const BusinessSwitcherButton(),
            SizedBox(width: AppSpacing.screenHorizontal.w),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal.w,
            vertical: AppSpacing.sm.h,
          ),
          children: [
            if (user != null) _AccountCard(user: user),
            SizedBox(height: AppSpacing.xxl.h),
            const _BusinessSection(),
            const AppSectionLabel('Security'),
            AppCard(
              padding: EdgeInsets.zero,
              child: BlocBuilder<AppLockCubit, AppLockState>(
                builder: (context, state) => SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('App lock'),
                  subtitle: const Text(
                    'Ask for Face ID, fingerprint or your device passcode '
                    'on open and after a minute away.',
                  ),
                  value: state.enabled,
                  onChanged: state.toggleStatus.isLoading
                      ? null
                      : (enabled) => unawaited(
                          context.read<AppLockCubit>().setEnabled(
                            enabled: enabled,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xxl.h),
            SizedBox(height: AppSpacing.xxl.h),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  'Sign out',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.error),
                ),
                onTap: () => unawaited(_confirmSignOut(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Sign out?',
      message:
          'Unsynced drafts on this device are kept and will sync when you '
          'sign back in.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed) await auth.signOut();
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photo = user.photoUrl;
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.accentMuted,
            foregroundImage: photo == null ? null : NetworkImage(photo),
            child: Text(
              user.initials,
              style: textTheme.titleSmall?.copyWith(color: AppColors.accent),
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Signed in',
                  style: textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The current business, the switcher, and links to its configuration.
class _BusinessSection extends StatelessWidget {
  const _BusinessSection();

  @override
  Widget build(BuildContext context) {
    final scope = context.watch<BusinessScopeCubit>().state;
    final business = scope.business;
    if (business == null) return const SizedBox.shrink();
    final role = scope.role;
    final textTheme = Theme.of(context).textTheme;
    final links = <_Link>[
      _Link(
        Icons.storefront_outlined,
        'Business details',
        role.canEditBusiness
            ? 'Name, time zone, form sections, numbering'
            : 'View name, time zone and settings',
        const BusinessDetailsRoute(),
      ),
      _Link(
        Icons.group_outlined,
        'Members',
        role.canManageMembers ? 'Add people and set roles' : 'Who has access',
        const MembersRoute(),
      ),
      const _Link(
        Icons.category_outlined,
        'Categories',
        'Group income and expenses',
        CategoriesRoute(),
      ),
      const _Link(
        Icons.dynamic_form_outlined,
        'Custom fields',
        'Extra inputs on entries',
        CustomFieldsRoute(),
      ),
      const _Link(
        Icons.people_outline_rounded,
        'Customers & suppliers',
        'Who you trade with',
        PartiesRoute(),
      ),
      const _Link(
        Icons.work_outline_rounded,
        'Projects',
        'Jobs, sites, engagements',
        ProjectsRoute(),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionLabel('Business'),
        AppCard(
          onTap: () => unawaited(showBusinessSwitcher(context)),
          child: Row(
            children: [
              BusinessAvatar(business: business, size: 44),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xxs.h),
                    Row(
                      children: [
                        RoleChip(role: role),
                        SizedBox(width: AppSpacing.sm.w),
                        Text(
                          business.archived
                              ? '${business.currency.code} · Archived'
                              : business.currency.code,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                'Switch',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md.h),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, link) in links.indexed) ...[
                if (index > 0) const Divider(),
                ListTile(
                  leading: Icon(link.icon),
                  title: Text(link.title),
                  subtitle: Text(link.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => unawaited(context.router.push(link.route)),
                ),
              ],
            ],
          ),
        ),
        if (role == Role.viewer) ...[
          SizedBox(height: AppSpacing.sm.h),
          Text(
            'You are a viewer here: you can see everything but not change '
            'it.',
            style: textTheme.bodySmall,
          ),
        ],
        SizedBox(height: AppSpacing.xxl.h),
      ],
    );
  }
}

class _Link {
  const _Link(this.icon, this.title, this.subtitle, this.route);

  final IconData icon;
  final String title;
  final String subtitle;
  final PageRouteInfo<void> route;
}
