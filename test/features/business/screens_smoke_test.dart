import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/business/logic/business_settings_cubit/business_settings_cubit.dart';
import 'package:business_ledger/features/business/screens/business_details_screen.dart';
import 'package:business_ledger/features/business/widgets/template_card.dart';
import 'package:business_ledger/features/categories/domain/const/category_kind.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/logic/categories_cubit/categories_cubit.dart';
import 'package:business_ledger/features/categories/screens/categories_screen.dart';
import 'package:business_ledger/features/categories/widgets/category_form_sheet.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/logic/parties_cubit/parties_cubit.dart';
import 'package:business_ledger/features/parties/screens/parties_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';
import '../../support/stub_auth_repository.dart';
import '../../support/stub_business_repositories.dart';

/// Cubits and stub streams are closed without awaiting: inside a widget
/// test's fake-async zone their done futures complete only on a later pump.
///
/// Renders the stage 6 screens with stub data under the real theme, so a
/// layout error (unbounded list, overflow) fails here rather than on device.
void main() {
  late StubAuthRepository auth;
  late StubBusinessRepository businesses;
  late StubMemberRepository members;
  late BusinessScopeCubit scope;

  Future<void> selectAs(Role role) async {
    await scope.select('b1');
    businesses
        .business('b1')
        .add(
          const Success(
            Business(
              id: 'b1',
              name: 'Rao Constructions',
              template: BusinessTemplate.construction,
            ),
          ),
        );
    members.membership('b1').add(Success(Member(uid: 'u1', role: role)));
  }

  setUp(() {
    auth = StubAuthRepository(initialUser: const AppUser(uid: 'u1'));
    businesses = StubBusinessRepository();
    members = StubMemberRepository();
    scope = BusinessScopeCubit(businesses, members, auth);
  });

  tearDown(() async {
    unawaited(scope.close());
    unawaited(auth.dispose());
    unawaited(businesses.dispose());
    unawaited(members.dispose());
  });

  testWidgets('categories: sections by kind, handles only for editors', (
    tester,
  ) async {
    final repository = StubCategoryRepository();
    final fields = StubCustomFieldRepository();
    final cubit = CategoriesCubit(repository, fields);
    {
      await selectAs(Role.editor);
      await cubit.watch('b1');
      repository.categories.add(
        const Success([
          Category(id: 'a', name: 'Sales', kind: CategoryKind.income),
          Category(
            id: 'b',
            name: 'Rent',
            kind: CategoryKind.expense,
            sortOrder: 1,
          ),
          Category(id: 'c', name: 'Old', sortOrder: 2, archived: true),
        ]),
      );
    }

    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: scope),
          BlocProvider.value(value: cubit),
        ],
        child: const CategoriesScreen(),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(2));
    // Archived sits collapsed.
    expect(find.text('Old'), findsNothing);
    await tester.tap(find.textContaining('ARCHIVED'));
    await _pumpFrames(tester);
    expect(find.text('Old'), findsOneWidget);

    unawaited(cubit.close());
    unawaited(repository.dispose());
    unawaited(fields.dispose());
  });

  testWidgets('business details are read-only for a viewer', (tester) async {
    final settings = BusinessSettingsCubit(businesses);
    await selectAs(Role.viewer);

    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: scope),
          BlocProvider.value(value: settings),
        ],
        child: const BusinessDetailsScreen(),
      ),
    );
    await _pumpFrames(tester);

    expect(find.textContaining('Only admins'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
    expect(find.text('Archive this business'), findsNothing);
    unawaited(settings.close());
  });

  testWidgets('parties list with filters renders', (tester) async {
    final repository = StubPartyRepository();
    final cubit = PartiesCubit(repository);
    {
      await selectAs(Role.admin);
      await cubit.watch('b1');
      repository.parties.add(
        const Success([Party(id: '1', name: 'Asha Traders')]),
      );
    }

    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: scope),
          BlocProvider.value(value: cubit),
        ],
        child: const PartiesScreen(),
      ),
    );
    await _pumpFrames(tester);
    expect(find.text('Asha Traders'), findsOneWidget);
    expect(find.text('Suppliers'), findsOneWidget);
    unawaited(cubit.close());
    unawaited(repository.dispose());
  });

  testWidgets('template card expands to preview seeded categories', (
    tester,
  ) async {
    await tester.pumpApp(
      const SingleChildScrollView(
        child: TemplateCard(
          template: BusinessTemplate.retail,
          selected: true,
          onTap: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stock purchases'), findsOneWidget);
    expect(find.textContaining('SKU / item code'), findsOneWidget);
  });

  testWidgets('category form refuses a blank name and returns the edit', (
    tester,
  ) async {
    Category? result;
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              result = await showCategoryForm(context, fields: const []),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(find.text('Give the category a name.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Fuel');
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(result?.name, 'Fuel');
    expect(result?.id, isEmpty);
    expect(result?.kind, CategoryKind.expense);
  });
}

void _noop() {}

/// Lets streams deliver and animations finish without `pumpAndSettle`,
/// which never settles while a skeleton shimmers.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}
