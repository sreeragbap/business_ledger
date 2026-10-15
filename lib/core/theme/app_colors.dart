import 'package:flutter/material.dart';

/// The dark palette. Dark is the primary (and for now only) theme.
///
/// Every text/background pair listed in `test/core/theme/app_colors_test.dart`
/// meets WCAG AA (4.5:1 for body text). Add a pair there when you add a token
/// meant to carry text.
abstract final class AppColors {
  // --- Surfaces, darkest first ---------------------------------------------

  /// The page behind everything.
  static const Color background = Color(0xFF0E0F11);

  /// Cards, the nav bar, list rows.
  static const Color surface = Color(0xFF16181C);

  /// A step up: inputs, sheets, dialogs, a card inside a card.
  static const Color surfaceRaised = Color(0xFF1D2025);

  /// Pressed rows, skeleton highlights, the selected nav indicator.
  static const Color surfaceHigh = Color(0xFF262A30);

  // --- Lines ---------------------------------------------------------------
  static const Color border = Color(0xFF2A2E35);
  static const Color borderStrong = Color(0xFF3A3F47);
  static const Color divider = Color(0xFF22252B);

  // --- Text ----------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF2F4F7);
  static const Color textSecondary = Color(0xFFA9B0BB);

  /// Captions and placeholders. The quietest text that still passes AA on
  /// [surfaceRaised].
  static const Color textTertiary = Color(0xFF8A929E);
  static const Color textDisabled = Color(0xFF5B626C);

  // --- Accent --------------------------------------------------------------
  // One restrained accent: teal. Used for the primary action, focus and the
  // selected tab — never for money direction, which has its own colours.

  static const Color accent = Color(0xFF2DD4BF);
  static const Color accentPressed = Color(0xFF14B8A6);

  /// Text and icons placed *on* [accent].
  static const Color onAccent = Color(0xFF04201C);

  static const Color accentMuted = Color(0x262DD4BF);

  // --- Semantic --------------------------------------------------------------
  // Money direction and status. Tuned for text on the dark surfaces.

  /// Money in: income, receipts, paid.
  static const Color income = Color(0xFF4ADE80);

  /// Money out: expenses, payments made.
  static const Color expense = Color(0xFFF87171);

  /// Overdue, and warnings that need attention but are not failures.
  static const Color warning = Color(0xFFFBBF24);

  /// Partial progress and neutral information.
  static const Color info = Color(0xFF60A5FA);

  /// Errors and destructive actions. Same hue family as [expense], separate
  /// so one can move without the other.
  static const Color error = Color(0xFFF87171);
  static const Color onError = Color(0xFF2A0707);

  /// Refunds and credits: money handed back, neither in nor out.
  static const Color refund = Color(0xFFC4B5FD);

  static const Color neutral = textSecondary;

  /// The tint behind a coloured label (chips, banners): the label's own hue
  /// at low opacity, so it reads as that colour without competing with text.
  static Color tint(Color colour) => colour.withValues(alpha: 0.14);

  // --- Swatches -------------------------------------------------------------
  // User-chosen colours for categories (keys shared with the seeded
  // templates: `functions/src/templates.ts`). Each passes AA as text on every
  // surface, so a swatch can colour an icon or a label. Deliberately not the
  // money colours: a green category is not "income".
  static const Color swatchGreen = Color(0xFF6EE7A0);
  static const Color swatchTeal = Color(0xFF5EEAD4);
  static const Color swatchAmber = Color(0xFFFCD34D);
  static const Color swatchPurple = Color(0xFFC4B5FD);
  static const Color swatchBlue = Color(0xFF7DB8FB);
  static const Color swatchGrey = Color(0xFFA9B0BB);
  static const Color swatchOrange = Color(0xFFFDA766);

  // --- Brand marks (third-party) ------------------------------------------
  static const Color googleBlue = Color(0xFF4285F4);

  // --- Misc ----------------------------------------------------------------
  static const Color scrim = Color(0xB3000000);
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Skeleton base and sweep.
  static const Color shimmerBase = surfaceRaised;
  static const Color shimmerHighlight = surfaceHigh;
}
