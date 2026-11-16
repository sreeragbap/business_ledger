import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Builds the app's [ThemeData]s, dark and light, from the tokens in this
/// folder. Both carry their [AppPalette] as a theme extension.
///
/// Must be read inside `ScreenUtilInit`: the text styles use `.sp`.
abstract final class AppTheme {
  static const Size _minTarget = Size.square(AppSpacing.minTouchTarget);

  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData get light => _build(AppPalette.light);

  static ThemeData _build(AppPalette p) {
    final isDark = p.brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentMuted,
      onPrimaryContainer: p.accent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceRaised,
      surfaceContainerHighest: p.surfaceHigh,
      error: p.error,
      onError: p.onError,
      outline: p.borderStrong,
      outlineVariant: p.border,
      scrim: p.scrim,
    );

    final textTheme = AppTextStyles.textTheme(p);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: AppRadius.button,
    );
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl.w,
      vertical: AppSpacing.md.h,
    );

    OutlineInputBorder inputBorder(Color colour, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colour, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      extensions: [p],
      colorScheme: colorScheme,
      // Transparent: every route paints `AppBackground` (the navy wash and
      // its glows) beneath its page; see `AppTransitions`.
      scaffoldBackgroundColor: AppColors.transparent,
      canvasColor: p.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: p.divider,
      iconTheme: IconThemeData(color: p.textSecondary),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: p.textPrimary,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.pageTitle(p).copyWith(fontSize: 24.sp),
        titleSpacing: AppSpacing.screenHorizontal.w,
        systemOverlayStyle:
            (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: AppColors.transparent,
                  systemNavigationBarColor: p.background,
                ),
      ),

      // A pastel pill with dark ink, floating on a soft glow — the solid
      // stand-in for the gradient used by `AppButton` and the shell.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? const Color(0xFFCDD8F4) : p.accent,
        foregroundColor: isDark ? p.onAccentGradient : p.onAccent,
        elevation: 6,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 2,
        shape: const StadiumBorder(),
        extendedTextStyle: textTheme.labelLarge,
        extendedPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: p.cardBorder),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.surfaceHigh,
          disabledForegroundColor: p.textDisabled,
          minimumSize: _minTarget,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.surfaceHigh,
          disabledForegroundColor: p.textDisabled,
          elevation: 0,
          minimumSize: _minTarget,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),

      // Ghost pill: a hairline of light around glass ("Mark as Complete").
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          backgroundColor: p.textPrimary.withValues(alpha: isDark ? 0.03 : 0),
          disabledForegroundColor: p.textDisabled,
          minimumSize: _minTarget,
          padding: buttonPadding,
          side: BorderSide(color: p.borderStrong),
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accent,
          disabledForegroundColor: p.textDisabled,
          minimumSize: _minTarget,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
          textStyle: textTheme.labelLarge,
          shape: buttonShape,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: _minTarget,
        ),
      ),

      // The "Upcoming / Past" switch: a glass pill track, the chosen
      // segment lit up as a brighter glass pill.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.accentMuted
                : p.surfaceRaised.withValues(alpha: 0.6),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? p.textDisabled
                : states.contains(WidgetState.selected)
                ? p.textPrimary
                : p.textSecondary,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.accent
                : p.textTertiary,
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          minimumSize: const WidgetStatePropertyAll(_minTarget),
          animationDuration: AppMotion.medium,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceRaised,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.w,
          vertical: AppSpacing.md.h + 2,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: p.textTertiary,
        ),
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: p.accent,
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: p.error),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.divider),
        focusedBorder: inputBorder(p.accent, 1.5),
        errorBorder: inputBorder(p.error),
        focusedErrorBorder: inputBorder(p.error, 1.5),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.3),
        selectionHandleColor: p.accent,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheet,
          side: BorderSide(color: p.border),
        ),
        modalBarrierColor: p.scrim,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
        barrierColor: p.scrim,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        height: 68.h,
        indicatorColor: p.accentMuted,
        overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.chip),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? p.textPrimary
                : p.textTertiary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? p.textPrimary
                : p.textTertiary,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceRaised.withValues(alpha: 0.7),
        selectedColor: p.accentMuted,
        disabledColor: p.surface,
        checkmarkColor: p.accent,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chip),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: p.accent,
        ),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: p.textPrimary,
        ),
        actionTextColor: p.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chip,
          side: BorderSide(color: p.borderStrong),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        minVerticalPadding: AppSpacing.md.h,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodyMedium,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.onAccent
              : p.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.borderStrong,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceHigh,
        circularTrackColor: AppColors.transparent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.surfaceHigh,
          borderRadius: AppRadius.input,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: p.textPrimary),
        waitDuration: AppMotion.slow,
      ),
    );
  }
}
