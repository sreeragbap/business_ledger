import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/const/category_style.dart';
import 'package:business_ledger/features/categories/domain/const/field_type.dart';
import 'package:flutter/material.dart';

/// A starting structure offered by `createBusiness`. Mirrors `TEMPLATES` in
/// `functions/src/templates.ts`, which is what is actually seeded; this copy
/// only drives the preview on the create screen, so a drift shows the user a
/// slightly wrong preview, never wrong data. Keep the two in step.
enum BusinessTemplate {
  general(
    'general',
    'General',
    'Sales, purchases and the usual overheads.',
    Icons.storefront_outlined,
    [..._common, StandardField.lineItems],
    [],
    [
      TemplateCategory(
        'Sales',
        CategoryKind.income,
        CategoryIcon.sell,
        CategoryColour.green,
      ),
      TemplateCategory(
        'Other income',
        CategoryKind.income,
        CategoryIcon.savings,
        CategoryColour.teal,
      ),
      TemplateCategory(
        'Purchases',
        CategoryKind.expense,
        CategoryIcon.shopping,
        CategoryColour.amber,
      ),
      TemplateCategory(
        'Rent',
        CategoryKind.expense,
        CategoryIcon.home,
        CategoryColour.purple,
      ),
      TemplateCategory(
        'Salaries',
        CategoryKind.expense,
        CategoryIcon.people,
        CategoryColour.blue,
      ),
      TemplateCategory(
        'Other expenses',
        CategoryKind.expense,
        CategoryIcon.receipt,
        CategoryColour.grey,
      ),
    ],
  ),
  retail(
    'retail',
    'Retail',
    'A shop: stock in, products out, with item codes.',
    Icons.local_mall_outlined,
    [..._common, StandardField.lineItems],
    [TemplateField('SKU / item code', FieldType.text)],
    [
      TemplateCategory(
        'Product sales',
        CategoryKind.income,
        CategoryIcon.sell,
        CategoryColour.green,
        ['SKU / item code'],
      ),
      TemplateCategory(
        'Stock purchases',
        CategoryKind.expense,
        CategoryIcon.inventory,
        CategoryColour.amber,
        ['SKU / item code'],
      ),
      TemplateCategory(
        'Supplier payments',
        CategoryKind.expense,
        CategoryIcon.payments,
        CategoryColour.orange,
      ),
      TemplateCategory(
        'Rent',
        CategoryKind.expense,
        CategoryIcon.home,
        CategoryColour.purple,
      ),
      TemplateCategory(
        'Utilities',
        CategoryKind.expense,
        CategoryIcon.bolt,
        CategoryColour.blue,
      ),
      TemplateCategory(
        'Other expenses',
        CategoryKind.expense,
        CategoryIcon.receipt,
        CategoryColour.grey,
      ),
    ],
  ),
  construction(
    'construction',
    'Construction',
    'Sites, materials, labour and transport, by project.',
    Icons.construction_rounded,
    [..._common, StandardField.lineItems, StandardField.project],
    [
      TemplateField('Site', FieldType.text),
      TemplateField('Unit', FieldType.select),
      TemplateField('Vehicle no.', FieldType.text),
    ],
    [
      TemplateCategory(
        'Contract income',
        CategoryKind.income,
        CategoryIcon.sell,
        CategoryColour.green,
      ),
      TemplateCategory(
        'Materials',
        CategoryKind.expense,
        CategoryIcon.inventory,
        CategoryColour.amber,
        ['Site', 'Unit'],
      ),
      TemplateCategory(
        'Labour',
        CategoryKind.expense,
        CategoryIcon.people,
        CategoryColour.blue,
        ['Site'],
      ),
      TemplateCategory(
        'Transport',
        CategoryKind.expense,
        CategoryIcon.truck,
        CategoryColour.orange,
        ['Vehicle no.'],
      ),
      TemplateCategory(
        'Equipment rental',
        CategoryKind.expense,
        CategoryIcon.build,
        CategoryColour.purple,
        ['Site'],
      ),
      TemplateCategory(
        'Contractor payments',
        CategoryKind.expense,
        CategoryIcon.payments,
        CategoryColour.teal,
      ),
      TemplateCategory(
        'Other expenses',
        CategoryKind.expense,
        CategoryIcon.receipt,
        CategoryColour.grey,
      ),
    ],
  ),
  services(
    'services',
    'Services',
    'Fees and retainers, with hours and projects.',
    Icons.handshake_outlined,
    [..._common, StandardField.lineItems, StandardField.project],
    [TemplateField('Hours', FieldType.number)],
    [
      TemplateCategory(
        'Service fees',
        CategoryKind.income,
        CategoryIcon.sell,
        CategoryColour.green,
        ['Hours'],
      ),
      TemplateCategory(
        'Retainers',
        CategoryKind.income,
        CategoryIcon.savings,
        CategoryColour.teal,
      ),
      TemplateCategory(
        'Software',
        CategoryKind.expense,
        CategoryIcon.laptop,
        CategoryColour.blue,
      ),
      TemplateCategory(
        'Travel',
        CategoryKind.expense,
        CategoryIcon.flight,
        CategoryColour.orange,
      ),
      TemplateCategory(
        'Subcontractors',
        CategoryKind.expense,
        CategoryIcon.people,
        CategoryColour.purple,
      ),
      TemplateCategory(
        'Other expenses',
        CategoryKind.expense,
        CategoryIcon.receipt,
        CategoryColour.grey,
      ),
    ],
  ),
  blank(
    'blank',
    'Start empty',
    'No categories. Build your own from scratch.',
    Icons.crop_square_rounded,
    _common,
    [],
    [],
  );

  const BusinessTemplate(
    this.key,
    this.label,
    this.description,
    this.icon,
    this.standardFields,
    this.fields,
    this.categories,
  );

  final String key;
  final String label;
  final String description;
  final IconData icon;
  final List<StandardField> standardFields;
  final List<TemplateField> fields;
  final List<TemplateCategory> categories;

  static BusinessTemplate fromKey(Object? key) =>
      values.firstWhere((template) => template.key == key, orElse: () => blank);
}

const List<StandardField> _common = [
  StandardField.party,
  StandardField.paymentMethod,
  StandardField.dueDate,
  StandardField.reference,
  StandardField.notes,
];

/// A seeded category, for the preview.
class TemplateCategory {
  const TemplateCategory(
    this.name,
    this.kind,
    this.icon,
    this.colour, [
    this.fieldLabels = const [],
  ]);

  final String name;
  final CategoryKind kind;
  final CategoryIcon icon;
  final CategoryColour colour;
  final List<String> fieldLabels;
}

/// A seeded custom field, for the preview.
class TemplateField {
  const TemplateField(this.label, this.type);

  final String label;
  final FieldType type;
}
