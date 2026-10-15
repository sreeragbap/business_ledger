import 'package:business_ledger/core/theme/app_colors.dart';
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

/// The curated colour set, mapped onto theme swatches that pass contrast on
/// every surface.
enum CategoryColour {
  green('green', 'Green', AppColors.swatchGreen),
  teal('teal', 'Teal', AppColors.swatchTeal),
  amber('amber', 'Amber', AppColors.swatchAmber),
  purple('purple', 'Purple', AppColors.swatchPurple),
  blue('blue', 'Blue', AppColors.swatchBlue),
  grey('grey', 'Grey', AppColors.swatchGrey),
  orange('orange', 'Orange', AppColors.swatchOrange);

  const CategoryColour(this.key, this.label, this.color);

  final String key;
  final String label;
  final Color color;

  static CategoryColour fromKey(Object? key) =>
      values.firstWhere((colour) => colour.key == key, orElse: () => grey);
}
