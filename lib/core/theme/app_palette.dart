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

  /// Deep navy night: glassy blue-grey surfaces, pastel periwinkle accent.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0A1120),
    surface: Color(0xFF111B2E),
    surfaceRaised: Color(0xFF17233A),
    surfaceHigh: Color(0xFF223049),
    border: Color(0xFF223050),
    borderStrong: Color(0xFF33446A),
    divider: Color(0xFF1A2640),
    textPrimary: Color(0xFFF3F5FA),
    textSecondary: Color(0xFFBCC5D8),
    textTertiary: Color(0xFF9BA7BF),
    textDisabled: Color(0xFF56627C),
    accent: Color(0xFFAFC3F5),
    accentPressed: Color(0xFF94ACEB),
    onAccent: Color(0xFF0D1426),
    accentMuted: Color(0x2EAFC3F5),
    income: Color(0xFF6EE7A8),
    expense: Color(0xFFFF8A8A),
    warning: Color(0xFFFCC75A),
    info: Color(0xFF8CBBFF),
    error: Color(0xFFFF8A8A),
    onError: Color(0xFF2A0707),
    refund: Color(0xFFD2C4FD),
    swatchGreen: Color(0xFF7DEBB0),
    swatchTeal: Color(0xFF6EE9DA),
    swatchAmber: Color(0xFFFCD34D),
    swatchPurple: Color(0xFFCDBEFD),
    swatchBlue: Color(0xFF8DC2FC),
    swatchGrey: Color(0xFFBCC5D8),
    swatchOrange: Color(0xFFFDAE70),
    scrim: Color(0xB3050A14),
  );

  /// The same roles on light, lavender-tinted surfaces: deeper hues so text
  /// keeps AA on white.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF1F3FA),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFECEFF8),
    surfaceHigh: Color(0xFFDFE4F2),
    border: Color(0xFFE0E5F1),
    borderStrong: Color(0xFFC5CDE0),
    divider: Color(0xFFE8ECF5),
    textPrimary: Color(0xFF0E1426),
    textSecondary: Color(0xFF444D63),
    textTertiary: Color(0xFF586178),
    textDisabled: Color(0xFFA2A9BA),
    accent: Color(0xFF34449A),
    accentPressed: Color(0xFF283680),
    onAccent: Color(0xFFFFFFFF),
    accentMuted: Color(0x1F34449A),
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
    scrim: Color(0x800E1426),
  );

  // --- Gradients -------------------------------------------------------------
  // Not lerped: they follow [brightness], which flips halfway through a
  // theme switch.

  bool get _isDark => brightness == Brightness.dark;

  /// The iridescent pastel fill of the main action (blue → pink → blue).
  /// Text on it is [onAccentGradient].
  LinearGradient get accentGradient => const LinearGradient(
    colors: [
      Color(0xFFA3C2F2),
      Color(0xFFDCD2F2),
      Color(0xFFF2CFE0),
      Color(0xFFA9C6F6),
    ],
    stops: [0, 0.4, 0.65, 1],
  );

  /// Ink on [accentGradient]; dark in both themes.
  Color get onAccentGradient => const Color(0xFF0D1426);

  /// The glass card: lit from the top-left, deepening to the page.
  LinearGradient get cardGradient => _isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF5233453), Color(0xF0182540), Color(0xF01A223D)],
          stops: [0, 0.6, 1],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFAFFFFFF)],
        );

  /// The page wash: navy night, brighter blue towards the top. The glows in
  /// [backgroundGlows] are laid over it.
  LinearGradient get backgroundGradient => _isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF16253F),
            Color(0xFF0E182C),
            Color(0xFF091121),
            Color(0xFF070C17),
          ],
          stops: [0, 0.3, 0.65, 1],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3E9F8), Color(0xFFEFF1FA), Color(0xFFF4F4FA)],
          stops: [0, 0.4, 1],
        );

  /// Soft light pooling on the page: a blue sky glow from the top-left, a
  /// dusk plum glow through the middle, a faint blue at the bottom-right.
  List<RadialGradient> get backgroundGlows => _isDark
      ? const [
          RadialGradient(
            center: Alignment(-0.9, -1.05),
            radius: 1.1,
            colors: [Color(0x403C6AA6), Color(0x003C6AA6)],
          ),
          RadialGradient(
            center: Alignment(0.45, 0.05),
            radius: 1,
            colors: [Color(0x2E633A5C), Color(0x00633A5C)],
          ),
          RadialGradient(
            center: Alignment(1.1, 0.95),
            radius: 0.9,
            colors: [Color(0x242A4F86), Color(0x002A4F86)],
          ),
        ]
      : const [
          RadialGradient(
            center: Alignment(-0.9, -1.05),
            radius: 1.1,
            colors: [Color(0x66C3D3F4), Color(0x00C3D3F4)],
          ),
          RadialGradient(
            center: Alignment(0.6, 0.1),
            radius: 1,
            colors: [Color(0x4DF1D6E6), Color(0x00F1D6E6)],
          ),
        ];

  /// The card edge: a hairline of light that separates content from the
  /// page wash.
  Color get cardBorder =>
      _isDark ? const Color(0x24FFFFFF) : const Color(0xFFDDE3F0);

  /// The shadow that lifts cards off the page.
  Color get cardShadow =>
      _isDark ? const Color(0x73000000) : const Color(0x2234449A);

  /// The glass bar / chip fill: translucent so the page shows through blur.
  Color get glass =>
      _isDark ? const Color(0xCC1A2438) : const Color(0xE6FFFFFF);

  /// The soft glow under raised gradient elements.
  Color get glow => _isDark ? const Color(0x406F8FE0) : const Color(0x2634449A);

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
