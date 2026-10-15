import 'package:flutter/material.dart';

/// What a custom field holds. Keys are checked by the `fields` rule in
/// `firestore.rules` and listed in `FIELD_TYPES` (`functions/src/templates.ts`).
///
/// How a transaction stores each value in `customFields{fieldId: value}`:
/// text → `String`, number → `num`, date → `yyyy-MM-dd` `String`,
/// select → one of the field's `options`, checkbox → `bool`.
enum FieldType {
  text('text', 'Text', Icons.short_text_rounded),
  number('number', 'Number', Icons.pin_outlined),
  date('date', 'Date', Icons.event_outlined),
  select('select', 'Choice', Icons.arrow_drop_down_circle_outlined),
  checkbox('checkbox', 'Yes / no', Icons.check_box_outlined);

  const FieldType(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static FieldType fromKey(Object? key) =>
      values.firstWhere((type) => type.key == key, orElse: () => text);

  bool get hasOptions => this == select;
}
