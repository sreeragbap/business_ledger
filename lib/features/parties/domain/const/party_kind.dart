import 'package:flutter/material.dart';

/// Who a party is to the business. Keys are checked by the `parties` rule.
enum PartyKind {
  customer('customer', 'Customer', 'Customers', Icons.person_outline_rounded),
  supplier('supplier', 'Supplier', 'Suppliers', Icons.local_shipping_outlined),
  both('both', 'Customer & supplier', 'Both', Icons.swap_horiz_rounded);

  const PartyKind(this.key, this.label, this.pluralLabel, this.icon);

  final String key;
  final String label;
  final String pluralLabel;
  final IconData icon;

  static PartyKind fromKey(Object? key) =>
      values.firstWhere((kind) => kind.key == key, orElse: () => customer);

  bool get isCustomer => this != supplier;
  bool get isSupplier => this != customer;

  /// Whether a party of this kind belongs under a [filter]: a "both" party
  /// shows under customers and under suppliers.
  bool matches(PartyKind filter) => switch (filter) {
    PartyKind.customer => isCustomer,
    PartyKind.supplier => isSupplier,
    PartyKind.both => this == PartyKind.both,
  };
}
