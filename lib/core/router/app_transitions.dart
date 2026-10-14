import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:flutter/widgets.dart';

/// Route transitions for `CustomRoute`s. Short and quiet: a fade, plus a
/// small rise for pushed pages so depth reads without a full slide.
abstract final class AppTransitions {
  static const Duration duration = AppMotion.medium;

  static Widget fade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: AppMotion.standard),
    child: child,
  );

  static Widget fadeRise(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standard,
      reverseCurve: AppMotion.standard.flipped,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
