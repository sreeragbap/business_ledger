import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/const/category_style.dart';
import 'package:business_ledger/features/categories/domain/const/field_type.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    const category = Category(
      id: 'c1',
      name: 'Materials',
      kind: CategoryKind.expense,
      icon: CategoryIcon.inventory,
      colour: CategoryColour.amber,
      fieldIds: ['f1', 'f2'],
      sortOrder: 3,
    );

    test('round-trips through toMap', () {
      expect(Category.fromMap('c1', category.toMap()), category);
    });

    test('toMap always carries what validCategory checks', () {
      final map = const Category(id: '', name: ' Fuel ').toMap();
      expect(map['name'], 'Fuel');
      expect(map['kind'], isA<String>());
      expect(map['archived'], isA<bool>());
      expect(map['fieldIds'], isA<List<String>>());
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('reads the seeded shape, timestamps included', () {
      final at = DateTime.utc(2026);
      final read = Category.fromMap('c2', const {
        'name': 'Sales',
        'kind': 'income',
        'icon': 'sell',
        'colour': 'green',
        'fieldIds': <Object?>[],
        'sortOrder': 0,
        'archived': false,
        'createdAt': '2026-01-01T00:00:00+00:00',
        'updatedAt': '2026-01-01T00:00:00+00:00',
      });
      expect(read.kind, CategoryKind.income);
      expect(read.icon, CategoryIcon.sell);
      expect(read.createdAt, at.toLocal());
    });

    test('unknown keys fall back instead of throwing', () {
      final read = Category.fromMap('c', const {
        'kind': 'transfer',
        'icon': 'rocket',
        'colour': 'magenta',
        'sortOrder': 'first',
      });
      expect(read.kind, CategoryKind.any);
      expect(read.icon, CategoryIcon.receipt);
      expect(read.colour, CategoryColour.grey);
      expect(read.sortOrder, 0);
    });

    test('kind decides which directions may use it', () {
      expect(CategoryKind.income.allows(Direction.inflow), isTrue);
      expect(CategoryKind.income.allows(Direction.outflow), isFalse);
      expect(CategoryKind.expense.allows(Direction.outflow), isTrue);
      expect(CategoryKind.any.allows(Direction.outflow), isTrue);
    });
  });

  group('CustomField', () {
    test('round-trips through toMap', () {
      const field = CustomField(
        id: 'f1',
        label: 'Unit',
        type: FieldType.select,
        options: ['kg', 'bags'],
        required: true,
        sortOrder: 1,
      );
      expect(CustomField.fromMap('f1', field.toMap()), field);
    });

    test('options are written only for choice fields', () {
      const field = CustomField(id: 'f', label: 'Site', options: ['stale']);
      expect(field.toMap()['options'], isEmpty);
    });
  });

  group('Party', () {
    const party = Party(
      id: 'p1',
      name: 'Asha Traders',
      kind: PartyKind.both,
      phone: '+91 98765 43210',
      email: 'asha@example.com',
      address: 'MG Road',
    );

    test('round-trips through toMap', () {
      expect(Party.fromMap('p1', party.toMap()), party);
    });

    test('search matches name, email and phone ignoring spaces', () {
      expect(party.matchesQuery('trad'), isTrue);
      expect(party.matchesQuery('ASHA@'), isTrue);
      expect(party.matchesQuery('98765 432'), isTrue);
      expect(party.matchesQuery('zzz'), isFalse);
      expect(party.matchesQuery('  '), isTrue);
    });

    test('a "both" party shows under customers and suppliers', () {
      expect(PartyKind.both.matches(PartyKind.customer), isTrue);
      expect(PartyKind.both.matches(PartyKind.supplier), isTrue);
      expect(PartyKind.customer.matches(PartyKind.supplier), isFalse);
      expect(PartyKind.fromKey('vendor'), PartyKind.customer);
    });
  });

  group('Project', () {
    test('round-trips through toMap', () {
      const project = Project(
        id: 'j1',
        name: 'Villa',
        code: 'SITE-12',
        description: 'Phase 2',
        archived: true,
      );
      expect(Project.fromMap('j1', project.toMap()), project);
      expect(project.displayName, 'SITE-12 · Villa');
      expect(project.matchesQuery('site'), isTrue);
    });
  });
}
