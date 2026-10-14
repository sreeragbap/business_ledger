/// Lowercase word prefixes stored on a transaction as `searchTokens[]`, so
/// Firestore can answer "starts with" searches with `array-contains`.
///
/// Mirrors `searchTokens` in `functions/src/ledger.ts` exactly: both sides run
/// the `searchTokens` group of `shared/ledger_cases.json`. Lengths and sorting
/// are by UTF-16 code unit, which is what JavaScript's `slice` and default
/// `sort` use.
abstract final class SearchTokens {
  /// Prefixes longer than this are not indexed: nobody types 16 letters
  /// before expecting a match.
  static const int maxPrefixLength = 15;

  /// Caps the array so a long description cannot bloat the document.
  static const int maxTokens = 200;

  static final RegExp _separator = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  static List<String> of(List<String?> parts) {
    final tokens = <String>{};
    for (final part in parts) {
      if (part == null || part.isEmpty) continue;
      for (final word in part.toLowerCase().split(_separator)) {
        if (word.isEmpty) continue;
        final max = word.length < maxPrefixLength
            ? word.length
            : maxPrefixLength;
        for (var i = 1; i <= max; i++) {
          tokens.add(word.substring(0, i));
        }
      }
    }
    final sorted = tokens.toList()..sort((a, b) => a.compareTo(b));
    return sorted.length > maxTokens ? sorted.sublist(0, maxTokens) : sorted;
  }
}
