import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/ledger/search_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the `searchTokens` group of `shared/ledger_cases.json`, which the
/// Cloud Functions suite runs against `functions/src/ledger.ts` too.
void main() {
  final cases =
      (jsonDecode(File('shared/ledger_cases.json').readAsStringSync())
              as Map<String, dynamic>)['searchTokens']
          as List<dynamic>;

  group('SearchTokens fixtures', () {
    for (final (index, raw) in cases.indexed) {
      final c = raw as Map<String, dynamic>;
      final parts = (c['parts'] as List<dynamic>).cast<String?>();
      final expected = (c['expect'] as List<dynamic>).cast<String>();
      test('case $index: $parts', () {
        expect(SearchTokens.of(parts), expected);
      });
    }
  });

  group('SearchTokens limits', () {
    test('prefixes stop at 15 characters', () {
      final tokens = SearchTokens.of(['abcdefghijklmnopqrstuvwxyz']);
      expect(tokens, hasLength(15));
      expect(tokens.last, 'abcdefghijklmno');
    });

    test('caps the list at 200, keeping the first in sorted order', () {
      final words = List.generate(40, (i) => 'w${'$i'.padLeft(2, '0')}xyzab');
      final tokens = SearchTokens.of([words.join(' ')]);
      expect(tokens, hasLength(200));
      final sorted = [...tokens]..sort();
      expect(tokens, sorted);
    });

    test('empty and null parts produce nothing', () {
      expect(SearchTokens.of([null, '', '  ', '--']), isEmpty);
    });
  });
}
