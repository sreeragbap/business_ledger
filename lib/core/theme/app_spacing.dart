/// Spacing scale. 4pt base.
///
/// These are **design units** on the 393x852 frame, not device pixels. Scale
/// them at the point of use, where the axis is known:
///
/// ```dart
/// SizedBox(height: AppSpacing.lg.h)
/// EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal.w)
/// ```
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Default horizontal page padding used by every screen.
  static const double screenHorizontal = 16;

  /// Minimum interactive size (Material and Apple HIG both ask for ~48).
  /// Not scaled: it is an accessibility floor, not a design measurement.
  static const double minTouchTarget = 48;
}
