import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppButtonVariant {
  /// Filled accent: the one main action on a screen.
  primary,

  /// Outlined: an alternative of equal weight but less emphasis.
  secondary,

  /// Text only: tertiary actions, inline links.
  text,
}

/// The app's button. Wraps the themed Material buttons and adds a loading
/// state that keeps the button's size, so the layout does not jump.
///
/// While [isLoading] the button ignores taps; a null [onPressed] disables it.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.destructive = false,
    super.key,
  });

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.destructive = false,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = false,
    this.destructive = false,
    super.key,
  }) : variant = AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// Fill the available width. Defaults on for primary and secondary.
  final bool expand;

  /// Paints the button in the error colour, for delete / cancel actions.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? () {} : onPressed;
    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      spinnerColour: switch (variant) {
        AppButtonVariant.primary =>
          destructive ? context.colors.onError : context.colors.onAccent,
        _ => destructive ? context.colors.error : context.colors.accent,
      },
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: onTap,
        style: destructive
            ? FilledButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: context.colors.onError,
              )
            : null,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: onTap,
        style: destructive
            ? OutlinedButton.styleFrom(
                foregroundColor: context.colors.error,
                side: BorderSide(color: context.colors.error),
              )
            : null,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: onTap,
        style: destructive
            ? TextButton.styleFrom(foregroundColor: context.colors.error)
            : null,
        child: child,
      ),
    };

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: isLoading ? '$label, loading' : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.spinnerColour,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color spinnerColour;

  @override
  Widget build(BuildContext context) {
    // The label stays laid out (invisible) under the spinner, so the button
    // keeps its width when it starts loading.
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20.r),
          SizedBox(width: AppSpacing.sm.w),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: isLoading ? 0 : 1,
          duration: AppMotion.fast,
          child: content,
        ),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: isLoading
              ? SizedBox.square(
                  key: const ValueKey('loading'),
                  dimension: 20.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: spinnerColour,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('idle')),
        ),
      ],
    );
  }
}
