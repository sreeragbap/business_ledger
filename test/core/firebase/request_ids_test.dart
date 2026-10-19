import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('request ids match what the RPCs accept, and are unique', () {
    final ids = List.generate(500, (_) => RequestIds.next());
    for (final id in ids) {
      expect(RequestIds.pattern.hasMatch(id), isTrue, reason: id);
      expect(id, hasLength(32));
    }
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('row ids are uuids, as the uuid columns want', () {
    final id = RequestIds.rowId();
    final uuid = RegExp(
      '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}'
      r'-[0-9a-f]{12}$',
    );
    expect(uuid.hasMatch(id), isTrue, reason: id);
  });

  test('RPC results become JSON maps all the way down', () {
    final converted = RpcClient.asJsonMap(<Object?, Object?>{
      'id': 'tx1',
      'nested': <Object?, Object?>{'paidMinor': 500},
      'lines': [
        <Object?, Object?>{'amountMinor': 1},
      ],
    });
    expect(converted['nested'], isA<Map<String, dynamic>>());
    expect(
      (converted['lines'] as List<Object?>).first,
      isA<Map<String, dynamic>>(),
    );
    expect(RpcClient.asJsonMap(null), isEmpty);
  });
}
