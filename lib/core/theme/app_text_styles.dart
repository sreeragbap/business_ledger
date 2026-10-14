import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Typography scale. Feeds `ThemeData.textTheme`; widgets read styles from
/// `Theme.of(context).textTheme` and `copyWith` weight or colour, never size.
///
/// Getters rather than constants because `.sp` reads the live screen.
/// No font is bundled yet; the platform default (SF Pro / Roboto) is used.
abstract final class AppTextStyles {
  static TextStyle _style(
    double size,
    FontWeight weight, {
    double height = 1.3,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) => TextStyle(
    fontSize: size.sp,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
  );

  /// Hero figures: the dashboard balance.
  static TextStyle get displayLarge =>
      _style(34, FontWeight.w700, height: 1.15, letterSpacing: -0.5);
  static TextStyle get displayMedium =>
      _style(28, FontWeight.w700, height: 1.2, letterSpacing: -0.3);
  static TextStyle get displaySmall => _style(24, FontWeight.w700);

  static TextStyle get headlineLarge => _style(22, FontWeight.w700);
  static TextStyle get headlineMedium => _style(20, FontWeight.w600);
  static TextStyle get headlineSmall => _style(18, FontWeight.w600);

  static TextStyle get titleLarge => _style(18, FontWeight.w600);
  static TextStyle get titleMedium => _style(16, FontWeight.w600);
  static TextStyle get titleSmall => _style(14, FontWeight.w600);

  static TextStyle get bodyLarge => _style(16, FontWeight.w400, height: 1.45);
  static TextStyle get bodyMedium => _style(
    14,
    FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );
  static TextStyle get bodySmall => _style(
    12,
    FontWeight.w400,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  static TextStyle get labelLarge =>
      _style(15, FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get labelMedium => _style(
    13,
    FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );
  static TextStyle get labelSmall => _style(
    11,
    FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  /// Equal-width digits, so amounts in a column line up. Apply to any style
  /// that shows money: `AppTextStyles.tabular(textTheme.titleMedium!)`.
  static TextStyle tabular(TextStyle style) => style.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
