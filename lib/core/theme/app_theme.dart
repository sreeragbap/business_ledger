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
      scaffoldBackgroundColor: p.background,
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
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle:
            (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: AppColors.transparent,
                  systemNavigationBarColor: p.surface,
                ),
      ),

      // Light: a solid accent button with white text, so it stands out on
      // white. Dark: Material's default tonal look (muted accent, accent
      // text), spelled out so a theme switch fades between the two.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? p.accentMuted : p.accent,
        foregroundColor: isDark ? p.accent : p.onAccent,
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: p.border),
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

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
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
        backgroundColor: p.surfaceRaised,
        modalBackgroundColor: p.surfaceRaised,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        modalBarrierColor: p.scrim,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
        barrierColor: p.scrim,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        height: 68.h,
        indicatorColor: p.accentMuted,
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
                ? p.accent
                : p.textTertiary,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceRaised,
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
        backgroundColor: p.surfaceHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: p.textPrimary,
        ),
        actionTextColor: p.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.input,
          side: BorderSide(color: p.borderStrong),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        minVerticalPadding: AppSpacing.md.h,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
        titleTextStyle: textTheme.bodyLarge,
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
