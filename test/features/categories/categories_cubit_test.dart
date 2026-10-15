import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/const/field_type.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/logic/categories_cubit/categories_cubit.dart';
import 'package:business_ledger/features/categories/logic/custom_fields_cubit/custom_fields_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_business_repositories.dart';

/// Income and expense categories interleaved, as a user might have sorted
/// them: sortOrder is global, sections are by kind.
const _sales = Category(id: 'sales', name: 'Sales', kind: CategoryKind.income);
const _rent = Category(
  id: 'rent',
  name: 'Rent',
  kind: CategoryKind.expense,
  sortOrder: 1,
);
const _fees = Category(
  id: 'fees',
  name: 'Fees',
  kind: CategoryKind.income,
  sortOrder: 2,
);
const _fuel = Category(
  id: 'fuel',
  name: 'Fuel',
  kind: CategoryKind.expense,
  sortOrder: 3,
);
const _wages = Category(
  id: 'wages',
  name: 'Wages',
  kind: CategoryKind.expense,
  sortOrder: 4,
);
const _old = Category(
  id: 'old',
  name: 'Old',
  kind: CategoryKind.expense,
  sortOrder: 9,
  archived: true,
);

void main() {
  late StubCategoryRepository categories;
  late StubCustomFieldRepository fields;

  setUp(() {
    categories = StubCategoryRepository();
    fields = StubCustomFieldRepository();
  });

  tearDown(() async {
    await categories.dispose();
    await fields.dispose();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<CategoriesCubit> loaded([
    List<Category> items = const [_sales, _rent, _fees, _fuel, _wages, _old],
  ]) async {
    final cubit = CategoriesCubit(categories, fields);
    await cubit.watch('b1');
    categories.categories.add(Success(items));
    await settle();
    return cubit;
  }

  group('CategoriesCubit', () {
    test('groups active categories by kind and keeps archived apart', () async {
      final cubit = await loaded();
      expect(cubit.state.activeOf(CategoryKind.expense).map((c) => c.id), [
        'rent',
        'fuel',
        'wages',
      ]);
      expect(cubit.state.activeOf(CategoryKind.income).map((c) => c.id), [
        'sales',
        'fees',
      ]);
      expect(cubit.state.archived, [_old]);
      await cubit.close();
    });

    test('reorder within a kind writes only the changed sortOrders', () async {
      final cubit = await loaded();
      // Move Wages to the top of the expense section.
      await cubit.reorder(CategoryKind.expense, 2, 0);

      // Global order becomes sales, wages, fees, rent, fuel.
      expect(categories.reorders.single, {'wages': 1, 'rent': 3, 'fuel': 4});
      expect(cubit.state.activeOf(CategoryKind.expense).map((c) => c.id), [
        'wages',
        'rent',
        'fuel',
      ]);
      // Income untouched; archived untouched and still present.
      expect(cubit.state.activeOf(CategoryKind.income).map((c) => c.id), [
        'sales',
        'fees',
      ]);
      expect(cubit.state.archived, [_old]);
      expect(cubit.state.actionStatus.isSuccess, isTrue);
      await cubit.close();
    });

    test('reorder normalises duplicate orders from older data', () async {
      final cubit = await loaded([
        _rent.copyWith(sortOrder: 0),
        _fuel.copyWith(sortOrder: 0),
      ]);
      await cubit.reorder(CategoryKind.expense, 0, 1);
      // Fuel already holds 0; only Rent needs a distinct number.
      expect(categories.reorders.single, {'rent': 1});
      expect(cubit.state.active.map((c) => c.id), ['fuel', 'rent']);
      await cubit.close();
    });

    test('a no-op drag writes nothing', () async {
      final cubit = await loaded();
      await cubit.reorder(CategoryKind.expense, 1, 1);
      expect(categories.reorders, isEmpty);
      await cubit.close();
    });

    test('a new category goes last', () async {
      final cubit = await loaded();
      await cubit.save(const Category(id: '', name: '  Travel '));
      final created = categories.created.single;
      expect(created.name, 'Travel');
      expect(created.sortOrder, 10);
      expect(cubit.state.actionStatus.message, 'Category added.');
      await cubit.close();
    });

    test('a blank name is refused before writing', () async {
      final cubit = await loaded();
      await cubit.save(const Category(id: '', name: ' '));
      expect(cubit.state.actionStatus.errorFor('name'), isNotNull);
      expect(categories.created, isEmpty);
      await cubit.close();
    });

    test('archive and unarchive; restored categories go last', () async {
      final cubit = await loaded();
      await cubit.archive(_rent);
      await cubit.unarchive(_old);
      expect(categories.archiveCalls, [
        ('rent', true, null),
        ('old', false, 5),
      ]);
      await cubit.close();
    });

    test('delete of a category in use offers archiving instead', () async {
      categories.deleteResult = const Failure(
        AppException(
          kind: AppErrorKind.inUse,
          message:
              'Transactions use this category, so it cannot be deleted. '
              'Archive it instead.',
        ),
      );
      final cubit = await loaded();
      await cubit.delete(_fuel);
      expect(categories.deleteCalls, ['fuel']);
      expect(cubit.state.deleteBlockedByUse, isTrue);
      expect(cubit.state.targetId, 'fuel');
      expect(cubit.state.actionStatus.message, contains('Archive it instead'));
      await cubit.close();
    });

    test('other delete failures are not mistaken for "in use"', () async {
      categories.deleteResult = const Failure(AppException.offline());
      final cubit = await loaded();
      await cubit.delete(_fuel);
      expect(cubit.state.deleteBlockedByUse, isFalse);
      expect(cubit.state.actionStatus.error?.isOffline, isTrue);
      await cubit.close();
    });

    test('resolves attached fields in order, skipping missing ones', () async {
      final cubit = await loaded();
      fields.fields.add(
        const Success([
          CustomField(id: 'f1', label: 'Site'),
          CustomField(id: 'f2', label: 'Unit'),
        ]),
      );
      await settle();
      final materials = _fuel.copyWith(fieldIds: ['f2', 'gone', 'f1']);
      expect(cubit.state.fieldsOf(materials).map((f) => f.label), [
        'Unit',
        'Site',
      ]);
      await cubit.close();
    });
  });

  group('CustomFieldsCubit', () {
    test('validate mirrors the rules and choice needs', () {
      expect(
        CustomFieldsCubit.validate(const CustomField(id: '', label: '')),
        contains('label'),
      );
      expect(
        CustomFieldsCubit.validate(
          const CustomField(id: '', label: 'Unit', type: FieldType.select),
        ),
        contains('options'),
      );
      expect(
        CustomFieldsCubit.validate(
          const CustomField(
            id: '',
            label: 'Unit',
            type: FieldType.select,
            options: ['kg', 'kg'],
          ),
        ),
        contains('options'),
      );
      expect(
        CustomFieldsCubit.validate(const CustomField(id: '', label: 'Site')),
        isEmpty,
      );
    });

    test('reorder writes the changed sortOrders', () async {
      final cubit = CustomFieldsCubit(fields);
      await cubit.watch('b1');
      fields.fields.add(
        const Success([
          CustomField(id: 'a', label: 'A'),
          CustomField(id: 'b', label: 'B', sortOrder: 1),
          CustomField(id: 'c', label: 'C', sortOrder: 2),
        ]),
      );
      await settle();
      await cubit.reorder(2, 0);
      expect(fields.reorders.single, {'c': 0, 'a': 1, 'b': 2});
      expect(cubit.state.active.map((f) => f.id), ['c', 'a', 'b']);
      await cubit.close();
    });

    test('a new select field keeps trimmed choices and goes last', () async {
      final cubit = CustomFieldsCubit(fields);
      await cubit.watch('b1');
      fields.fields.add(
        const Success([CustomField(id: 'a', label: 'A', sortOrder: 4)]),
      );
      await settle();
      await cubit.save(
        const CustomField(
          id: '',
          label: ' Unit ',
          type: FieldType.select,
          options: [' kg', 'bags '],
        ),
      );
      final created = fields.created.single;
      expect(created.label, 'Unit');
      expect(created.options, ['kg', 'bags']);
      expect(created.sortOrder, 5);
      await cubit.close();
    });
  });
}
