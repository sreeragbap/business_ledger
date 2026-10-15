import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/logic/business_settings_cubit/business_settings_cubit.dart';
import 'package:business_ledger/features/business/logic/members_cubit/members_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_business_repositories.dart';

const _editor = Member(uid: 'u2', role: Role.editor, displayName: 'Esha');

void main() {
  group('MembersCubit', () {
    late StubMemberRepository repository;

    setUp(() => repository = StubMemberRepository());
    tearDown(() => repository.dispose());

    Future<MembersCubit> watching() async {
      final cubit = MembersCubit(repository);
      await cubit.watch('b1');
      return cubit;
    }

    test('streams the member list', () async {
      final cubit = await watching();
      repository.members.add(const Success([_editor]));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.members, [_editor]);
      expect(cubit.state.loadStatus.isSuccess, isTrue);
      await cubit.close();
    });

    test('an invalid email is refused without a call', () async {
      final cubit = await watching();
      await cubit.add(email: 'not-an-email', role: Role.editor);
      expect(cubit.state.actionStatus.errorFor('email'), isNotNull);
      expect(repository.calls, isEmpty);
      await cubit.close();
    });

    test('the function message is shown when adding fails', () async {
      repository.addResult = const Failure(
        AppException(
          kind: AppErrorKind.notFound,
          message:
              'No account uses that email yet. Ask them to sign in to the '
              'app once, then add them.',
        ),
      );
      final cubit = await watching();
      await cubit.add(email: ' New@Example.com ', role: Role.viewer);
      expect(repository.calls, ['add:New@Example.com:viewer']);
      expect(cubit.state.action, MemberAction.add);
      expect(cubit.state.actionStatus.message, startsWith('No account'));
      await cubit.close();
    });

    blocTest<MembersCubit, MembersState>(
      'change role reports progress on that member, then success',
      build: () => MembersCubit(repository),
      act: (cubit) async {
        await cubit.watch('b1');
        await cubit.changeRole(_editor, Role.viewer);
      },
      skip: 1,
      expect: () => [
        isA<MembersState>()
            .having((s) => s.isBusy('u2'), 'busy', isTrue)
            .having((s) => s.action, 'action', MemberAction.changeRole),
        isA<MembersState>().having(
          (s) => s.actionStatus,
          'status',
          const Status.success(message: 'Esha is now a viewer.'),
        ),
      ],
      verify: (_) => expect(repository.calls, ['role:u2:viewer']),
    );

    test('transfer asks the server for the owner role', () async {
      final cubit = await watching();
      await cubit.transferOwnership(_editor);
      expect(repository.calls, ['role:u2:owner']);
      expect(cubit.state.action, MemberAction.transfer);
      await cubit.close();
    });

    test('leaving removes yourself', () async {
      final cubit = await watching();
      await cubit.leave('u1');
      expect(repository.calls, ['remove:u1']);
      expect(cubit.state.action, MemberAction.leave);
      expect(cubit.state.actionStatus.isSuccess, isTrue);
      await cubit.close();
    });
  });

  group('BusinessSettingsCubit', () {
    late StubBusinessRepository repository;

    setUp(() => repository = StubBusinessRepository());
    tearDown(() => repository.dispose());

    test('saves valid details', () async {
      final cubit = BusinessSettingsCubit(repository);
      await cubit.save(
        'b1',
        name: 'Shop',
        description: '',
        timezone: 'Asia/Kolkata',
        settings: const BusinessSettings(),
      );
      expect(repository.updateCalls, ['b1']);
      expect(cubit.state.saveStatus.isSuccess, isTrue);
      await cubit.close();
    });

    test('rejects an empty name and a bad prefix with field errors', () async {
      final cubit = BusinessSettingsCubit(repository);
      await cubit.save(
        'b1',
        name: ' ',
        description: '',
        timezone: 'Asia/Kolkata',
        settings: const BusinessSettings(invoicePrefix: 'IN V/'),
      );
      expect(cubit.state.saveStatus.errorFor('name'), isNotNull);
      expect(cubit.state.saveStatus.errorFor('invoicePrefix'), isNotNull);
      expect(repository.updateCalls, isEmpty);
      await cubit.close();
    });

    test('archive failure carries the message', () async {
      repository.archiveResult = const Failure(
        AppException(kind: AppErrorKind.permissionDenied, message: 'Nope.'),
      );
      final cubit = BusinessSettingsCubit(repository);
      await cubit.setArchived('b1', archived: true);
      expect(cubit.state.archiveStatus.message, 'Nope.');
      await cubit.close();
    });
  });
}
