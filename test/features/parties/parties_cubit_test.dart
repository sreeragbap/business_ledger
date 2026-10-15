import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/parties/domain/const/party_kind.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/logic/parties_cubit/parties_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/stub_business_repositories.dart';

const _asha = Party(id: '1', name: 'Asha Traders', phone: '98765 43210');
const _cement = Party(id: '2', name: 'Cement Co', kind: PartyKind.supplier);
const _both = Party(id: '3', name: 'Bala & Sons', kind: PartyKind.both);
const _gone = Party(id: '4', name: 'Gone Ltd', archived: true);

void main() {
  late StubPartyRepository repository;

  setUp(() => repository = StubPartyRepository());
  tearDown(() => repository.dispose());

  Future<PartiesCubit> loaded() async {
    final cubit = PartiesCubit(repository);
    await cubit.watch('b1');
    repository.parties.add(const Success([_asha, _cement, _both, _gone]));
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  test('hides archived parties until asked', () async {
    final cubit = await loaded();
    expect(cubit.state.visible, [_asha, _cement, _both]);
    expect(cubit.state.archivedCount, 1);
    cubit.toggleArchived();
    expect(cubit.state.visible, [_gone]);
    await cubit.close();
  });

  test('kind filter keeps "both" under customers and suppliers', () async {
    final cubit = await loaded()
      ..filterKind(PartyKind.supplier);
    expect(cubit.state.visible, [_cement, _both]);
    cubit.filterKind(PartyKind.customer);
    expect(cubit.state.visible, [_asha, _both]);
    cubit.filterKind(null);
    expect(cubit.state.visible, hasLength(3));
    await cubit.close();
  });

  test('search filters by name or phone', () async {
    final cubit = await loaded()
      ..search('43210');
    expect(cubit.state.visible, [_asha]);
    expect(cubit.state.isFiltering, isTrue);
    await cubit.close();
  });

  test('save validates, then creates and reports the new id', () async {
    final cubit = await loaded();
    await cubit.save(const Party(id: '', name: ' ', email: 'bad'));
    expect(cubit.state.actionStatus.errorFor('name'), isNotNull);
    expect(cubit.state.actionStatus.errorFor('email'), isNotNull);
    expect(repository.created, isEmpty);

    await cubit.save(const Party(id: '', name: 'New Co'));
    expect(repository.created.single.name, 'New Co');
    expect(cubit.state.savedId, 'p-new');
    expect(cubit.state.actionStatus.isSuccess, isTrue);
    await cubit.close();
  });
}
