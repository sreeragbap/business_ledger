import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_auth_repository.dart';
import '../../support/stub_business_repositories.dart';

const _user = AppUser(uid: 'u1', displayName: 'Asha');
const _business = Business(id: 'b1', name: 'Rao Constructions');
const _owner = Member(uid: 'u1', role: Role.owner);

void main() {
  late StubAuthRepository auth;
  late StubBusinessRepository businesses;
  late StubMemberRepository members;

  setUp(() {
    auth = StubAuthRepository(initialUser: _user);
    businesses = StubBusinessRepository();
    members = StubMemberRepository();
  });

  tearDown(() async {
    await auth.dispose();
    await businesses.dispose();
    await members.dispose();
  });

  BusinessScopeCubit build() => BusinessScopeCubit(businesses, members, auth);

  /// Lets the stubs' broadcast streams deliver.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  blocTest<BusinessScopeCubit, BusinessScopeState>(
    'restore with nothing remembered asks for the picker',
    build: build,
    act: (cubit) async => expect(await cubit.restore(), isNull),
    expect: () => const [BusinessScopeState(status: ScopeStatus.none)],
  );

  blocTest<BusinessScopeCubit, BusinessScopeState>(
    'restore reopens the remembered business and becomes ready once both '
    'documents arrive',
    build: () {
      businesses.lastIds['u1'] = 'b1';
      return build();
    },
    act: (cubit) async {
      expect(await cubit.restore(), 'b1');
      businesses.business('b1').add(const Success(_business));
      await settle();
      members.membership('b1').add(const Success(_owner));
    },
    expect: () => [
      const BusinessScopeState(status: ScopeStatus.loading, businessId: 'b1'),
      isA<BusinessScopeState>()
          .having((s) => s.status, 'status', ScopeStatus.loading)
          .having((s) => s.business, 'business', _business),
      isA<BusinessScopeState>()
          .having((s) => s.status, 'status', ScopeStatus.ready)
          .having((s) => s.role, 'role', Role.owner),
    ],
  );

  test('select persists the choice for this user', () async {
    final cubit = build();
    await cubit.select('b2');
    await settle();
    expect(businesses.rememberCalls, [('u1', 'b2')]);
    expect(await businesses.lastBusinessId('u1'), 'b2');
    expect(cubit.state.businessId, 'b2');
    await cubit.close();
  });

  test('a role change applies live', () async {
    final cubit = build();
    await cubit.select('b1');
    businesses.business('b1').add(const Success(_business));
    members.membership('b1').add(const Success(_owner));
    await settle();
    expect(cubit.state.role, Role.owner);

    members
        .membership('b1')
        .add(const Success(Member(uid: 'u1', role: Role.viewer)));
    await settle();
    expect(cubit.state.role, Role.viewer);
    expect(cubit.state.role.canEditConfig, isFalse);
    await cubit.close();
  });

  test(
    'being removed drops the selection with a reason, and forgets it',
    () async {
      final cubit = build();
      await cubit.select('b1');
      businesses.business('b1').add(const Success(_business));
      members.membership('b1').add(const Success(_owner));
      await settle();

      members.membership('b1').add(const Success(null));
      await settle();
      expect(cubit.state.status, ScopeStatus.none);
      expect(cubit.state.lostMessage, contains('Rao Constructions'));
      expect(businesses.rememberCalls.last, ('u1', null));
      await cubit.close();
    },
  );

  test(
    'permission denied on the business stream drops the selection',
    () async {
      final cubit = build();
      await cubit.select('b1');
      businesses
          .business('b1')
          .add(
            const Failure(
              AppException(
                kind: AppErrorKind.permissionDenied,
                message: 'denied',
              ),
            ),
          );
      await settle();
      expect(cubit.state.status, ScopeStatus.none);
      await cubit.close();
    },
  );

  test('a transient error keeps the data on screen', () async {
    final cubit = build();
    await cubit.select('b1');
    businesses.business('b1').add(const Success(_business));
    await settle();
    businesses.business('b1').add(const Failure(AppException.offline()));
    await settle();
    expect(cubit.state.business, _business);
    expect(cubit.state.loadStatus.isFailure, isTrue);
    expect(cubit.state.status, isNot(ScopeStatus.none));
    await cubit.close();
  });

  test('signing out resets the scope', () async {
    final cubit = build();
    await cubit.select('b1');
    auth.emitUser(null);
    await settle();
    expect(cubit.state, const BusinessScopeState());
    await cubit.close();
  });

  test('clear forgets the business and reports none', () async {
    final cubit = build();
    await cubit.select('b1');
    await cubit.clear(message: 'You left.');
    expect(cubit.state.status, ScopeStatus.none);
    expect(cubit.state.lostMessage, 'You left.');
    expect(businesses.rememberCalls.last, ('u1', null));
    await cubit.close();
  });
}
