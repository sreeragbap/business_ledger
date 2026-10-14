import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_logo.dart';
import 'package:business_ledger/features/app_lock/logic/app_lock_cubit/app_lock_cubit.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Covers the app until the user passes the system prompt. Opens the prompt
/// by itself on arrival; back is blocked while locked.
@RoutePage()
class LockScreen extends StatefulWidget implements AutoRouteWrapper {
  const LockScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<AppLockCubit>.value(value: getIt<AppLockCubit>()),
      BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
    ],
    child: this,
  );

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  Timer? _autoPrompt;

  @override
  void initState() {
    super.initState();
    // After the route transition, so the prompt does not open over a
    // half-faded screen.
    _autoPrompt = Timer(AppMotion.medium, () {
      if (mounted) unawaited(context.read<AppLockCubit>().unlock());
    });
  }

  @override
  void dispose() {
    _autoPrompt?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = context.select<AuthCubit, String>(
      (cubit) => cubit.state.user?.greetingName ?? 'there',
    );

    return BlocListener<AppLockCubit, AppLockState>(
      // Only a successful unlock pops. A reset on sign-out also clears
      // `locked`, but then App replaces the whole stack itself.
      listenWhen: (previous, current) =>
          previous.locked && !current.locked && current.unlockStatus.isSuccess,
      // Navigator.pop rather than maybePop: the PopScope below refuses
      // user-initiated pops, and this one is ours.
      listener: (context, _) => Navigator.of(context).pop(),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl.w),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const AppLogo(),
                  SizedBox(height: AppSpacing.xxl.h),
                  Text('Welcome back, $name', style: textTheme.headlineMedium),
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    'Business Ledger is locked.',
                    style: textTheme.bodyMedium,
                  ),
                  const Spacer(flex: 4),
                  BlocBuilder<AppLockCubit, AppLockState>(
                    buildWhen: (p, c) => p.unlockStatus != c.unlockStatus,
                    builder: (context, state) => Column(
                      children: [
                        AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: state.unlockStatus.isFailure
                              ? Padding(
                                  key: ValueKey(state.unlockStatus.message),
                                  padding: EdgeInsets.only(
                                    bottom: AppSpacing.md.h,
                                  ),
                                  child: Text(
                                    state.unlockStatus.message,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        AppButton(
                          label: 'Unlock',
                          icon: Icons.fingerprint_rounded,
                          isLoading: state.unlockStatus.isLoading,
                          onPressed: () => unawaited(
                            context.read<AppLockCubit>().unlock(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  AppButton.text(
                    label: 'Sign out',
                    onPressed: () =>
                        unawaited(context.read<AuthCubit>().signOut()),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
