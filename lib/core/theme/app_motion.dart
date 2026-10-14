import 'package:flutter/animation.dart';

/// Durations and curves, so every transition in the app moves alike.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);

  /// Route transitions, tab switches, state swaps.
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}
