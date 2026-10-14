import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('request ids match what the functions accept, and are unique', () {
    final ids = List.generate(500, (_) => RequestIds.next());
    for (final id in ids) {
      expect(RequestIds.pattern.hasMatch(id), isTrue, reason: id);
      expect(id, hasLength(32));
    }
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('callable results become JSON maps all the way down', () {
    final converted = CallableClient.asJsonMap(<Object?, Object?>{
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
    expect(CallableClient.asJsonMap(null), isEmpty);
  });
}
