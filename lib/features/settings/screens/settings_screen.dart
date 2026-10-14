import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/app_lock/logic/app_lock_cubit/app_lock_cubit.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Account and security settings. Business settings arrive in stage 6.
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
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal.w,
            vertical: AppSpacing.sm.h,
          ),
          children: [
            if (user != null) _AccountCard(user: user),
            SizedBox(height: AppSpacing.xxl.h),
            const _SectionLabel('Security'),
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
            const _SectionLabel('Business'),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Switch business'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => unawaited(
                  context.router.push(const BusinessPickerRoute()),
                ),
              ),
            ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xs.w,
        bottom: AppSpacing.sm.h,
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
