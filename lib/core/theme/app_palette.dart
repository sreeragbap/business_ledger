import 'package:flutter/material.dart';

/// The colour tokens of one theme. Two instances, [dark] and [light], ride on
/// `ThemeData.extensions`; widgets read the active one with
/// `context.colors` (see [AppPaletteContext]).
///
/// Every text/background pair listed in `test/core/theme/app_colors_test.dart`
/// meets WCAG AA (4.5:1 for body text) in both palettes. Add a pair there when
/// you add a token meant to carry text.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceHigh,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.accent,
    required this.accentPressed,
    required this.onAccent,
    required this.accentMuted,
    required this.income,
    required this.expense,
    required this.warning,
    required this.info,
    required this.error,
    required this.onError,
    required this.refund,
    required this.swatchGreen,
    required this.swatchTeal,
    required this.swatchAmber,
    required this.swatchPurple,
    required this.swatchBlue,
    required this.swatchGrey,
    required this.swatchOrange,
    required this.scrim,
  });

  final Brightness brightness;

  // --- Surfaces, page first --------------------------------------------------

  /// The page behind everything.
  final Color background;

  /// Cards, the nav bar, list rows.
  final Color surface;

  /// A step up: inputs, sheets, dialogs, a card inside a card.
  final Color surfaceRaised;

  /// Pressed rows, skeleton highlights, the selected nav indicator.
  final Color surfaceHigh;

  // --- Lines -----------------------------------------------------------------
  final Color border;
  final Color borderStrong;
  final Color divider;

  // --- Text ------------------------------------------------------------------
  final Color textPrimary;
  final Color textSecondary;

  /// Captions and placeholders. The quietest text that still passes AA on
  /// [surfaceRaised].
  final Color textTertiary;
  final Color textDisabled;

  // --- Accent ----------------------------------------------------------------
  // One restrained accent: teal. Used for the primary action, focus and the
  // selected tab — never for money direction, which has its own colours.

  final Color accent;
  final Color accentPressed;

  /// Text and icons placed *on* [accent].
  final Color onAccent;
  final Color accentMuted;

  // --- Semantic --------------------------------------------------------------
  // Money direction and status, tuned for text on this palette's surfaces.

  /// Money in: income, receipts, paid.
  final Color income;

  /// Money out: expenses, payments made.
  final Color expense;

  /// Overdue, and warnings that need attention but are not failures.
  final Color warning;

  /// Partial progress and neutral information.
  final Color info;

  /// Errors and destructive actions. Same hue family as [expense], separate
  /// so one can move without the other.
  final Color error;
  final Color onError;

  /// Refunds and credits: money handed back, neither in nor out.
  final Color refund;

  Color get neutral => textSecondary;

  // --- Swatches --------------------------------------------------------------
  // User-chosen colours for categories (`CategoryColor`). Each passes AA as
  // text on every surface, so a swatch can colour an icon or a label.
  // Deliberately not the money colours: a green category is not "income".
  final Color swatchGreen;
  final Color swatchTeal;
  final Color swatchAmber;
  final Color swatchPurple;
  final Color swatchBlue;
  final Color swatchGrey;
  final Color swatchOrange;

  // --- Misc ------------------------------------------------------------------
  final Color scrim;

  /// Skeleton base and sweep.
  Color get shimmerBase => surfaceRaised;
  Color get shimmerHighlight => surfaceHigh;

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0E0F11),
    surface: Color(0xFF16181C),
    surfaceRaised: Color(0xFF1D2025),
    surfaceHigh: Color(0xFF262A30),
    border: Color(0xFF2A2E35),
    borderStrong: Color(0xFF3A3F47),
    divider: Color(0xFF22252B),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFFA9B0BB),
    textTertiary: Color(0xFF8A929E),
    textDisabled: Color(0xFF5B626C),
    accent: Color(0xFF2DD4BF),
    accentPressed: Color(0xFF14B8A6),
    onAccent: Color(0xFF04201C),
    accentMuted: Color(0x262DD4BF),
    income: Color(0xFF4ADE80),
    expense: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    error: Color(0xFFF87171),
    onError: Color(0xFF2A0707),
    refund: Color(0xFFC4B5FD),
    swatchGreen: Color(0xFF6EE7A0),
    swatchTeal: Color(0xFF5EEAD4),
    swatchAmber: Color(0xFFFCD34D),
    swatchPurple: Color(0xFFC4B5FD),
    swatchBlue: Color(0xFF7DB8FB),
    swatchGrey: Color(0xFFA9B0BB),
    swatchOrange: Color(0xFFFDA766),
    scrim: Color(0xB3000000),
  );

  /// The same roles on light surfaces: deeper hues so text keeps AA on white.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEEF0F3),
    surfaceHigh: Color(0xFFE2E5EA),
    border: Color(0xFFE1E4E9),
    borderStrong: Color(0xFFC7CCD4),
    divider: Color(0xFFEBEDF0),
    textPrimary: Color(0xFF111418),
    textSecondary: Color(0xFF464E5A),
    textTertiary: Color(0xFF5A626E),
    textDisabled: Color(0xFFA2A8B1),
    accent: Color(0xFF0B6B63),
    accentPressed: Color(0xFF09564F),
    onAccent: Color(0xFFFFFFFF),
    accentMuted: Color(0x1F0B6B63),
    income: Color(0xFF137333),
    expense: Color(0xFFB42318),
    warning: Color(0xFF9A4A05),
    info: Color(0xFF1D4ED8),
    error: Color(0xFFB42318),
    onError: Color(0xFFFFFFFF),
    refund: Color(0xFF6D28D9),
    swatchGreen: Color(0xFF137333),
    swatchTeal: Color(0xFF0B6B63),
    swatchAmber: Color(0xFF8A5A00),
    swatchPurple: Color(0xFF7C3AED),
    swatchBlue: Color(0xFF1D5FD0),
    swatchGrey: Color(0xFF4B5563),
    swatchOrange: Color(0xFFB2410C),
    scrim: Color(0x80000000),
  );

  @override
  AppPalette copyWith() => this;

  /// Blends every colour, so a theme switch fades smoothly in step with
  /// the Material colours (`MaterialApp` animates between the two themes).
  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      refund: Color.lerp(refund, other.refund, t)!,
      swatchGreen: Color.lerp(swatchGreen, other.swatchGreen, t)!,
      swatchTeal: Color.lerp(swatchTeal, other.swatchTeal, t)!,
      swatchAmber: Color.lerp(swatchAmber, other.swatchAmber, t)!,
      swatchPurple: Color.lerp(swatchPurple, other.swatchPurple, t)!,
      swatchBlue: Color.lerp(swatchBlue, other.swatchBlue, t)!,
      swatchGrey: Color.lerp(swatchGrey, other.swatchGrey, t)!,
      swatchOrange: Color.lerp(swatchOrange, other.swatchOrange, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// `context.colors.accent`: the active palette.
extension AppPaletteContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
