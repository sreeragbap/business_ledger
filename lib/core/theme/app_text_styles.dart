import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Typography scale. Feeds `ThemeData.textTheme`; widgets read styles from
/// `Theme.of(context).textTheme` and `copyWith` weight or colour, never size.
///
/// Methods rather than constants because `.sp` reads the live screen; colours
/// come from the palette of the theme being built.
/// No font is bundled yet; the platform default (SF Pro / Roboto) is used.
abstract final class AppTextStyles {
  static TextStyle _style(
    double size,
    FontWeight weight, {
    required Color color,
    double height = 1.3,
    double letterSpacing = 0,
  }) => TextStyle(
    fontSize: size.sp,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// Hero figures: the dashboard balance.
  static TextStyle displayLarge(AppPalette p) => _style(
    34,
    FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: p.textPrimary,
  );
  static TextStyle displayMedium(AppPalette p) => _style(
    28,
    FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
    color: p.textPrimary,
  );
  static TextStyle displaySmall(AppPalette p) =>
      _style(24, FontWeight.w700, color: p.textPrimary);

  static TextStyle headlineLarge(AppPalette p) =>
      _style(22, FontWeight.w700, color: p.textPrimary);
  static TextStyle headlineMedium(AppPalette p) =>
      _style(20, FontWeight.w600, color: p.textPrimary);
  static TextStyle headlineSmall(AppPalette p) =>
      _style(18, FontWeight.w600, color: p.textPrimary);

  static TextStyle titleLarge(AppPalette p) =>
      _style(18, FontWeight.w600, color: p.textPrimary);
  static TextStyle titleMedium(AppPalette p) =>
      _style(16, FontWeight.w600, color: p.textPrimary);
  static TextStyle titleSmall(AppPalette p) =>
      _style(14, FontWeight.w600, color: p.textPrimary);

  static TextStyle bodyLarge(AppPalette p) =>
      _style(16, FontWeight.w400, height: 1.45, color: p.textPrimary);
  static TextStyle bodyMedium(AppPalette p) => _style(
    14,
    FontWeight.w400,
    height: 1.45,
    color: p.textSecondary,
  );
  static TextStyle bodySmall(AppPalette p) => _style(
    12,
    FontWeight.w400,
    height: 1.4,
    color: p.textTertiary,
  );

  static TextStyle labelLarge(AppPalette p) =>
      _style(15, FontWeight.w600, letterSpacing: 0.1, color: p.textPrimary);
  static TextStyle labelMedium(AppPalette p) => _style(
    13,
    FontWeight.w500,
    color: p.textSecondary,
    letterSpacing: 0.1,
  );
  static TextStyle labelSmall(AppPalette p) => _style(
    11,
    FontWeight.w500,
    color: p.textSecondary,
    letterSpacing: 0.2,
  );

  static TextTheme textTheme(AppPalette p) => TextTheme(
    displayLarge: displayLarge(p),
    displayMedium: displayMedium(p),
    displaySmall: displaySmall(p),
    headlineLarge: headlineLarge(p),
    headlineMedium: headlineMedium(p),
    headlineSmall: headlineSmall(p),
    titleLarge: titleLarge(p),
    titleMedium: titleMedium(p),
    titleSmall: titleSmall(p),
    bodyLarge: bodyLarge(p),
    bodyMedium: bodyMedium(p),
    bodySmall: bodySmall(p),
    labelLarge: labelLarge(p),
    labelMedium: labelMedium(p),
    labelSmall: labelSmall(p),
  );

  /// Equal-width digits, so amounts in a column line up. Apply to any style
  /// that shows money: `AppTextStyles.tabular(textTheme.titleMedium!)`.
  static TextStyle tabular(TextStyle style) => style.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
