import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// The curated icon set for categories. Keys are what is stored in
/// `categories/{id}.icon` and what `functions/src/templates.ts` seeds.
enum CategoryIcon {
  sell('sell', Icons.sell_outlined),
  savings('savings', Icons.savings_outlined),
  shopping('shopping', Icons.shopping_bag_outlined),
  home('home', Icons.home_outlined),
  people('people', Icons.people_outline_rounded),
  receipt('receipt', Icons.receipt_long_outlined),
  inventory('inventory', Icons.inventory_2_outlined),
  payments('payments', Icons.payments_outlined),
  bolt('bolt', Icons.bolt_rounded),
  truck('truck', Icons.local_shipping_outlined),
  build('build', Icons.build_outlined),
  laptop('laptop', Icons.laptop_mac_rounded),
  flight('flight', Icons.flight_rounded);

  const CategoryIcon(this.key, this.icon);

  final String key;
  final IconData icon;

  /// Unknown keys (a newer app's icon) show the neutral receipt.
  static CategoryIcon fromKey(Object? key) =>
      values.firstWhere((icon) => icon.key == key, orElse: () => receipt);
}

/// The curated colour set, mapped onto the palette's swatches, which pass
/// contrast on every surface in both themes.
enum CategoryColour {
  green('green', 'Green'),
  teal('teal', 'Teal'),
  amber('amber', 'Amber'),
  purple('purple', 'Purple'),
  blue('blue', 'Blue'),
  grey('grey', 'Grey'),
  orange('orange', 'Orange');

  const CategoryColour(this.key, this.label);

  final String key;
  final String label;

  /// This colour in [palette] (`context.colors`).
  Color colorIn(AppPalette palette) => switch (this) {
    green => palette.swatchGreen,
    teal => palette.swatchTeal,
    amber => palette.swatchAmber,
    purple => palette.swatchPurple,
    blue => palette.swatchBlue,
    grey => palette.swatchGrey,
    orange => palette.swatchOrange,
  };

  static CategoryColour fromKey(Object? key) =>
      values.firstWhere((colour) => colour.key == key, orElse: () => grey);
}
