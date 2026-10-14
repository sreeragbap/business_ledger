import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/constants/app_strings.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_fade_in.dart';
import 'package:business_ledger/core/widgets/app_logo.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/auth/domain/const/social_sign_in_method.dart';
import 'package:business_ledger/features/auth/logic/sign_in_cubit/sign_in_cubit.dart';
import 'package:business_ledger/features/auth/widgets/social_sign_in_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Social sign-in. Apple is offered on iOS only, where App Review requires
/// it alongside Google.
@RoutePage()
class SignInScreen extends StatelessWidget implements AutoRouteWrapper {
  const SignInScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) => BlocProvider<SignInCubit>(
    create: (_) => getIt<SignInCubit>(),
    child: this,
  );

  static bool get _offersApple => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final methods = [
      if (_offersApple) SocialSignInMethod.apple,
      SocialSignInMethod.google,
    ];

    return BlocListener<SignInCubit, SignInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status.isSuccess) {
          // replaceAll, so back cannot return here.
          unawaited(context.router.replaceAll([const HomeShellRoute()]));
        } else if (state.status.isFailure) {
          showAppSnackBar(
            context,
            state.status.message,
            kind: AppSnackBarKind.error,
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _Glow()),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl.w,
                  vertical: AppSpacing.lg.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    const AppLogo(size: 64),
                    SizedBox(height: AppSpacing.xxl.h),
                    AppFadeIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        'Business Ledger',
                        style: textTheme.displayMedium,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    AppFadeIn(
                      delay: const Duration(milliseconds: 140),
                      child: Text(
                        AppStrings.appTagline,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxxl.h),
                    for (final (index, point) in _points.indexed)
                      AppFadeIn(
                        delay: Duration(milliseconds: 220 + index * 70),
                        child: _SellingPoint(icon: point.$1, text: point.$2),
                      ),
                    const Spacer(flex: 3),
                    AppFadeIn(
                      delay: const Duration(milliseconds: 420),
                      child: BlocBuilder<SignInCubit, SignInState>(
                        builder: (context, state) => Column(
                          children: [
                            for (final method in methods) ...[
                              SocialSignInButton(
                                method: method,
                                isLoading: state.isLoading(method),
                                onPressed: state.status.isLoading
                                    ? null
                                    : () => unawaited(
                                        context.read<SignInCubit>().signIn(
                                          method,
                                        ),
                                      ),
                              ),
                              SizedBox(height: AppSpacing.md.h),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    Center(
                      child: Text(
                        'Your books stay private to the businesses you join.',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<(IconData, String)> _points = [
    (Icons.swap_vert_rounded, 'Income, expenses and who owes what'),
    (Icons.cloud_sync_outlined, 'Works offline, syncs when you are back'),
    (Icons.receipt_long_outlined, 'Invoices and receipts in a tap'),
  ];
}

class _SellingPoint extends StatelessWidget {
  const _SellingPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm.r),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18.r, color: AppColors.accent),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A faint accent wash in the top corner, for depth on the flat background.
class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.9, -1.1),
            radius: 1.1,
            colors: [
              AppColors.accent.withValues(alpha: 0.12),
              AppColors.background.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
