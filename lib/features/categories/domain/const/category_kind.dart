import 'package:business_ledger/core/ledger/ledger_enums.dart';

/// Which side of the ledger a category is offered on. Keys are checked by
/// `validCategory` in `firestore.rules`.
enum CategoryKind {
  income('income', 'Income', 'Money in'),
  expense('expense', 'Expense', 'Money out'),
  any('any', 'Both', 'Either direction');

  const CategoryKind(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;

  static CategoryKind fromKey(Object? key) =>
      values.firstWhere((kind) => kind.key == key, orElse: () => any);

  /// Whether a transaction moving money [direction] may use this category.
  /// For the transaction form's category picker.
  bool allows(Direction direction) => switch (this) {
    CategoryKind.any => true,
    CategoryKind.income => direction == Direction.inflow,
    CategoryKind.expense => direction == Direction.outflow,
  };
}
