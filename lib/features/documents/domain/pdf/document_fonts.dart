import 'package:pdf/widgets.dart' as pw;

/// The fonts a document is drawn with, and what they can draw.
///
/// The built-in PDF fonts (Helvetica) cover Latin-1 only: no ₹ or €, and
/// asking them for one throws. [canRender] lets the layout fall back to a
/// currency code, and [sanitise] keeps a stray character in a party name
/// from failing the whole render.
class DocumentFonts {
  const DocumentFonts({
    required this.regular,
    required this.bold,
    required this.canRenderRune,
    this.fallback = const [],
  });

  /// Helvetica, embedded in every PDF reader. Works offline and in tests.
  factory DocumentFonts.builtIn() => DocumentFonts(
    regular: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    canRenderRune: _latin1,
  );

  /// A Unicode TrueType family (Noto Sans) that covers ₹ € £ ¥.
  factory DocumentFonts.unicode({
    required pw.Font regular,
    required pw.Font bold,
    List<pw.Font> fallback = const [],
  }) => DocumentFonts(
    regular: regular,
    bold: bold,
    fallback: fallback,
    canRenderRune: _any,
  );

  final pw.Font regular;
  final pw.Font bold;
  final List<pw.Font> fallback;
  final bool Function(int rune) canRenderRune;

  bool canRender(String text) => text.runes.every(canRenderRune);

  /// [text] with anything the font cannot draw replaced. Typographic dashes
  /// and quotes get their ASCII look-alikes first.
  String sanitise(String text) {
    if (canRender(text)) return text;
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final replaced = _asciiFor[rune];
      if (canRenderRune(rune)) {
        buffer.writeCharCode(rune);
      } else if (replaced != null) {
        buffer.write(replaced);
      } else {
        buffer.write('?');
      }
    }
    return buffer.toString();
  }

  static bool _latin1(int rune) => rune >= 0x20 && rune <= 0xff || rune == 0x0a;
  static bool _any(int rune) => true;

  static const Map<int, String> _asciiFor = {
    0x2013: '-',
    0x2014: '-',
    0x2018: "'",
    0x2019: "'",
    0x201C: '"',
    0x201D: '"',
    0x2022: '·',
    0x2026: '...',
    0x20AC: 'EUR ',
    0x20B9: 'INR ',
  };
}
