import 'package:bloc_test/bloc_test.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:business_ledger/features/business/logic/create_business_cubit/create_business_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_business_repositories.dart';

void main() {
  late StubBusinessRepository repository;

  setUp(() => repository = StubBusinessRepository());
  tearDown(() => repository.dispose());

  CreateBusinessCubit build() => CreateBusinessCubit(repository);

  test('starts on the general template, INR and a device time zone', () {
    final state = build().state;
    expect(state.template, BusinessTemplate.general);
    expect(state.currency, Currency.inr);
    expect(state.timezone, isNotEmpty);
  });

  blocTest<CreateBusinessCubit, CreateBusinessState>(
    'success carries the new business id',
    build: build,
    act: (cubit) async {
      cubit
        ..templateChanged(BusinessTemplate.construction)
        ..currencyChanged(Currency.byCode('USD'));
      await cubit.submit(name: ' Rao Constructions ', description: 'Villas');
    },
    skip: 2,
    expect: () => [
      isA<CreateBusinessState>().having(
        (s) => s.submitStatus,
        'submitStatus',
        const Status.loading(),
      ),
      isA<CreateBusinessState>()
          .having((s) => s.submitStatus.isSuccess, 'success', isTrue)
          .having((s) => s.createdBusinessId, 'id', 'b-new'),
    ],
    verify: (_) {
      final request = repository.createCalls.single;
      expect(request.name, 'Rao Constructions');
      expect(request.template, BusinessTemplate.construction);
      expect(request.currency.code, 'USD');
      expect(RequestIds.pattern.hasMatch(request.requestId), isTrue);
    },
  );

  blocTest<CreateBusinessCubit, CreateBusinessState>(
    'a blank name is refused before calling the server',
    build: build,
    act: (cubit) => cubit.submit(name: '   '),
    expect: () => [
      isA<CreateBusinessState>().having(
        (s) => s.submitStatus.errorFor('name'),
        'name error',
        isNotNull,
      ),
    ],
    verify: (_) => expect(repository.createCalls, isEmpty),
  );

  blocTest<CreateBusinessCubit, CreateBusinessState>(
    'a server validation error lands on the named field',
    build: () {
      repository.createResult = const Failure(
        AppException(
          kind: AppErrorKind.validation,
          message: 'Unknown time zone.',
          field: 'timezone',
        ),
      );
      return build();
    },
    act: (cubit) => cubit.submit(name: 'Shop'),
    skip: 1,
    expect: () => [
      isA<CreateBusinessState>()
          .having(
            (s) => s.submitStatus.message,
            'message',
            'Unknown time zone.',
          )
          .having(
            (s) => s.submitStatus.errorFor('timezone'),
            'field',
            'Unknown time zone.',
          ),
    ],
  );

  blocTest<CreateBusinessCubit, CreateBusinessState>(
    'offline is reported with the offline message',
    build: () {
      repository.createResult = const Failure(AppException.offline());
      return build();
    },
    act: (cubit) => cubit.submit(name: 'Shop'),
    skip: 1,
    expect: () => [
      isA<CreateBusinessState>().having(
        (s) => s.submitStatus.error?.isOffline,
        'offline',
        isTrue,
      ),
    ],
  );

  test('a retry of the same input reuses the request id', () async {
    repository.createResult = const Failure(
      AppException(kind: AppErrorKind.timeout, message: 'slow'),
    );
    final cubit = build();
    await cubit.submit(name: 'Shop');
    await cubit.submit(name: 'Shop');
    expect(repository.createCalls, hasLength(2));
    expect(
      repository.createCalls[0].requestId,
      repository.createCalls[1].requestId,
    );
    await cubit.close();
  });

  test('changing the input starts a new request id', () async {
    repository.createResult = const Failure(AppException.offline());
    final cubit = build();
    await cubit.submit(name: 'Shop');
    await cubit.submit(name: 'Shop two');
    expect(
      repository.createCalls[0].requestId,
      isNot(repository.createCalls[1].requestId),
    );
    await cubit.close();
  });

  test('after a success, the next create is a new intent', () async {
    final cubit = build();
    await cubit.submit(name: 'Shop');
    await cubit.submit(name: 'Shop');
    expect(
      repository.createCalls[0].requestId,
      isNot(repository.createCalls[1].requestId),
    );
    await cubit.close();
  });
}
