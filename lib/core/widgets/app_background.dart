import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:flutter/widgets.dart';

/// The page backdrop: the palette's navy wash with its soft glows on top.
///
/// Every route paints one under its page (see `AppTransitions`), so pages
/// stay opaque while scaffolds and app bars are transparent and show it.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    var layered = child;
    for (final glow in colors.backgroundGlows.reversed) {
      layered = DecoratedBox(
        decoration: BoxDecoration(gradient: glow),
        child: layered,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: colors.backgroundGradient),
      child: layered,
    );
  }
}
