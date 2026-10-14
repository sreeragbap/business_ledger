import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/features/auth/domain/const/social_sign_in_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A provider button. Apple's follows its guidelines for dark backgrounds
/// (white fill, black mark); Google's is a raised dark surface.
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.method,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final SocialSignInMethod method;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isApple = method == SocialSignInMethod.apple;
    final background = isApple ? AppColors.white : AppColors.surfaceRaised;
    final foreground = isApple ? AppColors.black : AppColors.textPrimary;

    return Semantics(
      button: true,
      label: isLoading ? '${method.label}, signing in' : method.label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: 54.h < AppSpacing.minTouchTarget
            ? AppSpacing.minTouchTarget
            : 54.h,
        child: FilledButton(
          onPressed: isLoading ? () {} : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background.withValues(alpha: 0.5),
            disabledForegroundColor: foreground.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.button,
              side: isApple
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.borderStrong),
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: isLoading
                ? SizedBox.square(
                    key: const ValueKey('loading'),
                    dimension: 20.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: foreground,
                    ),
                  )
                : Row(
                    key: const ValueKey('idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProviderMark(method: method, color: foreground),
                      SizedBox(width: AppSpacing.md.w),
                      Text(
                        method.label,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: foreground),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.method, required this.color});

  final SocialSignInMethod method;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 22.r;
    return switch (method) {
      SocialSignInMethod.apple => Icon(Icons.apple, size: size, color: color),
      // No brand asset is bundled; a lettermark keeps the button honest
      // without shipping Google's logo before the asset pass.
      SocialSignInMethod.google => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: Text(
          'G',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.googleBlue,
            height: 1,
          ),
        ),
      ),
    };
  }
}
