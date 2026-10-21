import 'package:flutter/material.dart';

/// Colours that are the same in every theme. Themed tokens (surfaces, text,
/// accent, money colours, swatches) live in `AppPalette` and are read with
/// `context.colors`.
abstract final class AppColors {
  /// The tint behind a coloured label (chips, banners): the label's own hue
  /// at low opacity, so it reads as that colour without competing with text.
  static Color tint(Color colour) => colour.withValues(alpha: 0.14);

  // --- Brand marks (third-party) ------------------------------------------
  static const Color googleBlue = Color(0xFF4285F4);

  // --- Misc ----------------------------------------------------------------
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
