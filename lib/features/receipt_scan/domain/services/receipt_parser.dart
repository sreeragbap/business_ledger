import 'dart:math';

import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/ocr_line.dart';
import 'package:business_ledger/features/receipt_scan/domain/models/receipt_scan.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';

/// Turns recognised receipt text into a [ReceiptScan]. Pure and offline.
///
/// Heuristics, tuned for shop and restaurant bills (Indian GST invoices
/// first): the total is the amount on the best "grand total / net amount /
/// total" row, the date the first real calendar date, the shop the first
/// name-like line at the top. Anything unsure is left out rather than
/// guessed; the user reviews every value before it fills the form.
abstract final class ReceiptParser {
  static ReceiptScan parse(
    List<OcrLine> lines, {
    required Currency currency,
    required DateTime now,
  }) {
    final rows = groupRows(lines).map(_fold).toList();
    if (rows.isEmpty) return const ReceiptScan();
    final (total, items) = _checkedTotal(rows, currency);
    // The seller prints above the buyer: look for its details there.
    final buyerAt = rows.indexWhere(
      // "Buyer (Bill to)", not "Buyer's Order No.".
      (row) => RegExp(
        r"\b(buyer(?!'s)|bill to|billed to|consignee|ship to)\b",
        caseSensitive: false,
      ).hasMatch(row),
    );
    final sellerRows = buyerAt <= 0 ? rows : rows.sublist(0, buyerAt);
    return ReceiptScan(
      totalMinor: total,
      // Day first everywhere except the US.
      date: _date(rows, now: now, dayFirst: currency.code != 'USD'),
      merchant: _merchant(rows),
      reference: _reference(rows),
      paymentMethod: _paymentMethod(rows),
      lineItems: items,
      // The company's PAN prints anywhere, often at the foot.
      sellerGstin: _gstin(sellerRows, pan: _pan(rows)),
      sellerPhone: _phone(sellerRows),
      sellerEmail: _email(sellerRows),
      sellerAddress: _address(sellerRows),
    );
  }

  // --- Rows ------------------------------------------------------------------

  /// Letters ML Kit's Latin model reads into English print ("Automobiłes",
  /// "Invoicę No."), back to plain ASCII.
  static const Map<String, String> _lookAlikes = {
    'ł': 'l',
    'Ł': 'L',
    'ę': 'e',
    'Ę': 'E',
    'ą': 'a',
    'Ą': 'A',
    'ı': 'i',
    'ȷ': 'j',
  };

  static String _fold(String row) => row.replaceAllMapped(
    RegExp('[${_lookAlikes.keys.join()}]'),
    (match) => _lookAlikes[match.group(0)]!,
  );

  /// Joins lines that sit on the same printed row, left to right, with two
  /// spaces between them, and orders rows top to bottom. Recognisers often
  /// return "Total" and "1,240.00" as separate lines.
  ///
  /// A tilted or creased photo makes printed rows slope, so an item's name
  /// can sit half a line lower than its amount across the page. Each line is
  /// matched along the slope of the rows around it (a crease bends rows one
  /// way at the top of a page and the other way at the bottom).
  static List<String> groupRows(List<OcrLine> lines) {
    final texts = [
      for (final line in lines)
        if (line.text.trim().isNotEmpty) line,
    ];
    if (texts.isEmpty) return const [];
    final heights = [for (final line in texts) line.height]..sort();
    final window = heights[heights.length ~/ 2] * 6;
    final slopes = [
      for (final line in texts)
        _rowSlope([
          for (final other in texts)
            if ((other.centerY - line.centerY).abs() <= window) other,
        ]),
    ];

    final rows = <List<int>>[];
    final byTop = List.generate(texts.length, (i) => i)
      ..sort((a, b) => texts[a].centerY.compareTo(texts[b].centerY));
    for (final i in byTop) {
      final line = texts[i];
      List<int>? match;
      var closest = double.infinity;
      for (final row in rows) {
        // Measured against the row's nearest line, so a curved row still
        // holds together.
        final near = row.reduce(
          (a, b) =>
              (texts[a].centerX - line.centerX).abs() <=
                  (texts[b].centerX - line.centerX).abs()
              ? a
              : b,
        );
        final other = texts[near];
        final height = min(other.height, line.height);
        if (height <= 0 || row.any((j) => _stacked(texts[j], line))) continue;
        final slope = (slopes[i] + slopes[near]) / 2;
        final off =
            (line.centerY -
                    other.centerY -
                    slope * (line.centerX - other.centerX))
                .abs();
        if (off < height * 0.5 && off < closest) {
          closest = off;
          match = row;
        }
      }
      if (match != null) {
        match.add(i);
      } else {
        rows.add([i]);
      }
    }

    // Top to bottom by where each row crosses the middle of the page.
    final middle =
        (texts.map((l) => l.left).reduce(min) +
            texts.map((l) => l.right).reduce(max)) /
        2;
    double level(List<int> row) =>
        row
            .map(
              (i) => texts[i].centerY - slopes[i] * (texts[i].centerX - middle),
            )
            .reduce((a, b) => a + b) /
        row.length;
    final levels = {for (final row in rows) row: level(row)};
    rows.sort((a, b) => levels[a]!.compareTo(levels[b]!));
    return [
      for (final row in rows)
        ([for (final i in row) texts[i]]
              ..sort((a, b) => a.left.compareTo(b.left)))
            .map((line) => line.text.trim())
            .join('  '),
    ];
  }

  /// The row slope (rise over run) that joins [lines] into the fewest rows:
  /// level unless a slope does better, else the middle of the best range.
  static double _rowSlope(List<OcrLine> lines) {
    if (lines.length < 2) return 0;
    const steps = 40;
    const maxSlope = 0.1; // about 6°
    final level = _rowCount(lines, 0);
    var best = level;
    var bestRun = (start: 0, length: 0);
    var run = (start: 0, length: 0);
    for (var i = 0; i <= 2 * steps; i++) {
      final count = _rowCount(lines, maxSlope * (i - steps) / steps);
      if (count < best) {
        best = count;
        run = (start: i, length: 1);
        bestRun = run;
      } else if (count == best && best < level) {
        run = run.start + run.length == i
            ? (start: run.start, length: run.length + 1)
            : (start: i, length: 1);
        if (run.length > bestRun.length) bestRun = run;
      }
    }
    if (best == level) return 0;
    final middle = bestRun.start + (bestRun.length - 1) / 2;
    return maxSlope * (middle - steps) / steps;
  }

  /// How many rows [lines] make when rows slope by [slope].
  static int _rowCount(List<OcrLine> lines, double slope) {
    double level(OcrLine line) => line.centerY - slope * line.centerX;
    final sorted = [...lines]..sort((a, b) => level(a).compareTo(level(b)));
    var count = 0;
    final row = <OcrLine>[];
    for (final line in sorted) {
      final first = row.firstOrNull;
      final height = first == null ? 0.0 : min(first.height, line.height);
      if (first == null ||
          height <= 0 ||
          (level(line) - level(first)).abs() >= height * 0.5 ||
          row.any((other) => _stacked(other, line))) {
        count++;
        row.clear();
      }
      row.add(line);
    }
    return count;
  }

  /// Whether two lines overlap side to side: one is above the other, so
  /// they are never on the same row.
  static bool _stacked(OcrLine a, OcrLine b) =>
      min(a.right, b.right) - max(a.left, b.left) >
      0.2 * min(a.right - a.left, b.right - b.left);

  // --- Total -----------------------------------------------------------------

  static final RegExp _amount = RegExp(
    // 1,23,456.78 · 1234.5 · 5.950.00 (OCR read the comma as a dot) ·
    // 1 234,56 is not supported (rare on receipts).
    r'(?<![\d.,/:\-])'
    r'(\d{1,3}(?:,\d{2,3})+|\d{1,3}(?:\.\d{3})+(?=[.,]\d{1,2}(?!\d))|\d+)'
    // Not a rate: "14%", "14 %".
    r'(?:[.,](\d{1,2}))?(?![\d/:%])(?!\s%)',
  );

  static const List<String> _strongTotal = [
    'grand total',
    'net total',
    'nett total',
    'net amount',
    'net amt',
    'net payable',
    'total payable',
    'amount payable',
    'payable amount',
    'total amount',
    'total amt',
    'bill amount',
    'bill total',
    'invoice total',
    'invoice amount',
    'amount due',
    'total due',
    'balance due',
    'to pay',
  ];

  static const List<String> _notTotal = [
    'sub total',
    'subtotal',
    'sub-total',
    'total qty',
    'total quantity',
    'total item',
    'no of item',
    'items',
    'qty',
    'tax',
    'gst',
    'vat',
    'cess',
    'discount',
    'saved',
    'saving',
    'change',
    'tender',
    'round',
    'tip',
    'service charge',
  ];

  /// The total, checked against the rest of the receipt, and the items
  /// that add up to it.
  ///
  /// OCR misreads digits: "₹ 3,100.00" often comes out as "73,100.00". So
  /// the total row's amount, and the same without a leading 7 or 2 that may
  /// be the ₹ sign, are checked in turn: first against the amount in words
  /// ("Three Thousand One Hundred Only", which letters make reliable), then
  /// against the items and taxes adding up to it.
  static (int?, List<LineItem>) _checkedTotal(
    List<String> rows,
    Currency currency,
  ) {
    final read = _total(rows, currency);
    if (read == null) return (null, const []);
    final candidates = read.candidates;
    // The bill ends at its total. Below it come summaries of what is
    // already in the bill (the GST table by HSN and rate, the amount in
    // words, bank details): never items or tax lines of their own.
    final bill = rows.sublist(0, read.row);
    List<LineItem> itemsFor(int total) =>
        ReceiptItems.find(bill, total: total, currency: currency);

    final inWords = _amountInWords(rows, currency);
    if (inWords != null && candidates.contains(inWords)) {
      return (inWords, itemsFor(inWords));
    }
    // Items that add up on their own prove a total; a stand-in charges
    // line fits any total above the items, so it proves nothing.
    final found = [for (final candidate in candidates) itemsFor(candidate)];
    for (final (i, items) in found.indexed) {
      if (items.isNotEmpty && !ReceiptScan.hasStandInCharges(items)) {
        return (candidates[i], items);
      }
    }
    return (candidates.first, found.first);
  }

  /// The total as read (and without a ₹ misread as a digit), and the row
  /// that labels it.
  static ({List<int> candidates, int row})? _total(
    List<String> rows,
    Currency currency,
  ) {
    RegExpMatch? best;
    int? bestValue;
    var bestScore = 0;
    var bestRow = 0;
    for (var i = 0; i < rows.length; i++) {
      final text = rows[i].toLowerCase();
      final score = _strongTotal.any(text.contains)
          ? 3
          : _startsWord(text, _notTotal)
          ? 0
          : RegExp(r'\btotal\b').hasMatch(text)
          ? 2
          : RegExp(r'\b(amount|amt)\b').hasMatch(text)
          ? 1
          : 0;
      if (score == 0) continue;
      // The amount sits on the row, or alone on the next one.
      final match =
          _lastAmountMatch(rows[i], currency) ??
          (i + 1 < rows.length && _isAmountOnly(rows[i + 1])
              ? _lastAmountMatch(rows[i + 1], currency)
              : null);
      final amount = match == null ? null : _toMinor(match, currency);
      if (match == null || amount == null || amount == 0) continue;
      // Between rows as good, the larger amount: the grand total is above
      // the totals of a tax summary table.
      if (score > bestScore || (score == bestScore && amount > bestValue!)) {
        best = match;
        bestValue = amount;
        bestScore = score;
        bestRow = i;
      }
    }
    if (best != null && bestValue != null) {
      return (
        candidates: [
          bestValue,
          ?_withoutSymbol(best.group(0)!, currency),
        ],
        row: bestRow,
      );
    }

    // No total row: the largest amount with decimals is usually it.
    int? largest;
    var largestRow = 0;
    for (final (i, row) in rows.indexed) {
      for (final match in _amount.allMatches(row)) {
        if (match.group(2) == null) continue;
        final value = _toMinor(match, currency);
        if (value != null && (largest == null || value > largest)) {
          largest = value;
          largestRow = i;
        }
      }
    }
    return largest == null ? null : (candidates: [largest], row: largestRow);
  }

  /// [amount] read without its first digit when that digit may be a
  /// misread ₹ ("73,100.00" for "₹3,100.00"), or `null`.
  static int? _withoutSymbol(String amount, Currency currency) {
    if (amount.length < 2 || !'72'.contains(amount[0])) return null;
    final rest = amount.substring(1);
    if (!RegExp('^[1-9]').hasMatch(rest)) return null;
    final match = _amount.matchAsPrefix(rest);
    if (match == null || match.end != rest.length) return null;
    return _toMinor(match, currency);
  }

  // --- Amount in words -------------------------------------------------------

  static const Map<String, int> _numberWords = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fourty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  static const Map<String, int> _scaleWords = {
    'hundred': 100,
    'thousand': 1000,
    'lakh': 100000,
    'lakhs': 100000,
    'lac': 100000,
    'lacs': 100000,
    'million': 1000000,
    'crore': 10000000,
    'crores': 10000000,
  };

  static bool _isNumberWord(String word) =>
      _numberWords.containsKey(word) || _scaleWords.containsKey(word);

  /// The amount written out in words ("INR Three Thousand One Hundred
  /// Only"), in minor units, or `null`. Tax amounts in words are skipped.
  static int? _amountInWords(List<String> rows, Currency currency) {
    for (final row in rows) {
      final text = row.toLowerCase();
      if (_startsWord(text, const ['tax', 'gst'])) continue;
      final words = RegExp('[a-z]+').allMatches(text).map((m) => m[0]!);
      if (!words.any(
        (w) => const {
          'only',
          'rupees',
          'rupee',
          'inr',
          'rs',
          'dollars',
          'usd',
        }.contains(w),
      )) {
        continue;
      }
      final value = _wordsAmount(words.toList(), currency);
      if (value != null && value > 0) return value;
    }
    return null;
  }

  /// "three thousand one hundred [and twelve paise]" → minor units.
  static int? _wordsAmount(List<String> words, Currency currency) {
    // The longest run of number words, "and" allowed inside.
    var start = -1;
    var end = -1;
    for (var i = 0; i < words.length; i++) {
      if (!_isNumberWord(words[i])) continue;
      var j = i;
      while (j + 1 < words.length &&
          (_isNumberWord(words[j + 1]) ||
              (words[j + 1] == 'and' &&
                  j + 2 < words.length &&
                  _isNumberWord(words[j + 2])))) {
        j++;
      }
      if (j - i > end - start) {
        start = i;
        end = j;
      }
      i = j;
    }
    if (start < 0) return null;
    var run = words.sublist(start, end + 1);
    var fraction = <String>[];
    final hasFraction =
        end + 1 < words.length &&
        const {'paise', 'paisa', 'cents', 'cent'}.contains(words[end + 1]);
    if (hasFraction) {
      final and = run.lastIndexOf('and');
      if (and < 0) {
        fraction = run;
        run = const [];
      } else {
        fraction = run.sublist(and + 1);
        run = run.sublist(0, and);
      }
    }
    final major = run.isEmpty ? 0 : _wordsValue(run);
    final minor = fraction.isEmpty ? 0 : _wordsValue(fraction);
    if (major == null || minor == null) return null;
    final unit = pow(10, currency.decimals).toInt();
    if (minor >= unit && minor > 0) return null;
    return major * unit + minor;
  }

  static int? _wordsValue(List<String> words) {
    var total = 0;
    var current = 0;
    for (final word in words) {
      if (word == 'and') continue;
      if (_numberWords[word] case final value?) {
        current += value;
      } else if (word == 'hundred') {
        current = (current == 0 ? 1 : current) * 100;
      } else if (_scaleWords[word] case final scale?) {
        total += (current == 0 ? 1 : current) * scale;
        current = 0;
      } else {
        return null;
      }
    }
    return total + current;
  }

  /// [text] has a word starting with one of [words] ("tax" in "taxable").
  static bool _startsWord(String text, List<String> words) => RegExp(
    '(?<![a-z])(${words.map(RegExp.escape).join('|')})',
  ).hasMatch(text);

  /// [text] has one of [words] as a whole word ("tel" but not "hotel").
  static bool _hasWord(String text, List<String> words) => RegExp(
    '(?<![a-z])(${words.map(RegExp.escape).join('|')})(?![a-z])',
  ).hasMatch(text);

  /// A row holding just an amount. OCR often misreads ₹ as another glyph,
  /// so one or two non-ASCII characters may stand in for the symbol.
  static bool _isAmountOnly(String row) => RegExp(
    r'^\s*(?:₹|rs\.?|inr|\$|€|£|[^\x00-\x7F]{1,2})?\s*[\d,]+(?:[.,]\d{1,2})?\s*$',
    caseSensitive: false,
  ).hasMatch(row);

  /// A number followed by a unit is a quantity ("2 NOS", "3 pcs"), not money.
  static final RegExp _unitAfter = RegExp(
    r'^\s*(?:nos|no|pcs|pc|qty|kg|kgs|g|gm|ltr|l|ml|items?|units?|x)\b',
    caseSensitive: false,
  );

  /// The row's last amount, preferring ones printed with decimals.
  static int? _lastAmount(String row, Currency currency) {
    final match = _lastAmountMatch(row, currency);
    return match == null ? null : _toMinor(match, currency);
  }

  static RegExpMatch? _lastAmountMatch(String row, Currency currency) {
    RegExpMatch? last;
    RegExpMatch? lastDecimal;
    for (final match in _amount.allMatches(row)) {
      // Long digit runs without decimals are phone or bill numbers.
      if (match.group(2) == null && match.group(1)!.length > 7) continue;
      if (_unitAfter.hasMatch(row.substring(match.end))) continue;
      if (_toMinor(match, currency) == null) continue;
      last = match;
      if (match.group(2) != null) lastDecimal = match;
    }
    return lastDecimal ?? last;
  }

  static int? _toMinor(Match match, Currency currency) {
    final whole = match.group(1)!.replaceAll(RegExp('[,.]'), '');
    final fraction = match.group(2) ?? '';
    final digits = fraction.length > currency.decimals
        ? fraction.substring(0, currency.decimals)
        : fraction;
    return Money.parse(digits.isEmpty ? whole : '$whole.$digits', currency);
  }

  // --- Date ------------------------------------------------------------------

  static const List<String> _months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  static final RegExp _numericDate = RegExp(
    r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)',
  );
  static final RegExp _isoDate = RegExp(
    r'(?<!\d)(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})(?!\d)',
  );
  static final RegExp _dayMonthName = RegExp(
    // "0ct": OCR reads the O of Oct as a zero.
    r'(?<!\d)(\d{1,2})(?:st|nd|rd|th)?[\s\-.]*([a-z0][a-z]{2})[a-z]*\.?'
    r"[\s\-,']*(\d{4}|\d{2})(?!\d)",
    caseSensitive: false,
  );
  static final RegExp _monthNameDay = RegExp(
    r'\b([a-z]{3})[a-z]*\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})(?!\d)',
    caseSensitive: false,
  );

  /// A date right after one of these is not the bill date ("from
  /// 1-Apr-2021" in a shop's name, "valid till…", "due…").
  static final RegExp _notBillDate = RegExp(
    r'(from|since|w\.?e\.?f\.?|valid|till|until|upto|expir\w*|due|est\.?)'
    r'[\s:.\-]*$',
    caseSensitive: false,
  );
  static final RegExp _dateLabel = RegExp(
    r'\b(date|dated|dt|bill date|invoice date)\b',
    caseSensitive: false,
  );

  static String? _date(
    List<String> rows, {
    required DateTime now,
    required bool dayFirst,
  }) {
    // 1. A date on a row that labels it ("Date", "Dated", "3335 dt."), or
    //    on the row right below a label printed alone.
    for (var i = 0; i < rows.length; i++) {
      if (!_dateLabel.hasMatch(rows[i])) continue;
      final here = _datesIn(rows[i], now: now, dayFirst: dayFirst);
      if (here.isNotEmpty) return here.first;
      if (i + 1 < rows.length) {
        final below = _datesIn(rows[i + 1], now: now, dayFirst: dayFirst);
        if (below.isNotEmpty) return below.first;
      }
    }
    // 2. Otherwise the latest date on the receipt: the bill date is the
    //    newest of them (others are founding, registration, validity).
    String? latest;
    for (final row in rows) {
      for (final day in _datesIn(row, now: now, dayFirst: dayFirst)) {
        if (latest == null || day.compareTo(latest) > 0) latest = day;
      }
    }
    return latest;
  }

  /// The bill-date candidates in [row], in order: real calendar days, not
  /// in brackets and not after "from", "valid till", "due"…
  static List<String> _datesIn(
    String row, {
    required DateTime now,
    required bool dayFirst,
  }) {
    final found = <(int, String)>[];
    void add(RegExpMatch match, int year, int month, int day) {
      final before = row.substring(0, match.start);
      if (_notBillDate.hasMatch(before)) return;
      // Inside an unclosed bracket: "(from 1-Apr-2021)".
      if (before.lastIndexOf('(') > before.lastIndexOf(')')) return;
      final key = _validDay(year, month, day, now);
      if (key != null) found.add((match.start, key));
    }

    for (final match in _isoDate.allMatches(row)) {
      add(
        match,
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    for (final match in _numericDate.allMatches(row)) {
      final a = int.parse(match.group(1)!);
      final b = int.parse(match.group(2)!);
      final year = _fullYear(match.group(3)!);
      // A part above 12 can only be the day.
      final asDayFirst = a > 12 || (dayFirst && b <= 12);
      asDayFirst ? add(match, year, b, a) : add(match, year, a, b);
    }
    for (final match in _dayMonthName.allMatches(row)) {
      final month = _monthIndex(match.group(2)!);
      if (month == null) continue;
      add(match, _fullYear(match.group(3)!), month, int.parse(match.group(1)!));
    }
    for (final match in _monthNameDay.allMatches(row)) {
      final month = _monthIndex(match.group(1)!);
      if (month == null) continue;
      add(match, int.parse(match.group(3)!), month, int.parse(match.group(2)!));
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, day) in found) day];
  }

  static int? _monthIndex(String name) {
    final index = _months.indexOf(
      name.toLowerCase().substring(0, 3).replaceFirst(RegExp('^0'), 'o'),
    );
    return index < 0 ? null : index + 1;
  }

  static int _fullYear(String year) =>
      year.length == 2 ? 2000 + int.parse(year) : int.parse(year);

  /// `yyyy-MM-dd` for a real calendar day from 2000 to tomorrow (time zones),
  /// else `null`.
  static String? _validDay(int year, int month, int day, DateTime now) {
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 2000) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    if (date.isAfter(tomorrow)) return null;
    final key = LedgerDates.key(date);
    return LedgerDates.isValid(key) ? key : null;
  }

  // --- Shop ------------------------------------------------------------------

  static const List<String> _notMerchant = [
    'invoice',
    'receipt',
    'bill',
    'cash memo',
    'estimate',
    'gstin',
    'gst no',
    'fssai',
    'cin',
    'pan',
    'phone',
    'tel',
    'mob',
    'mobile',
    'ph',
    'email',
    'www',
    'http',
    '@',
    'welcome',
    'original',
    'duplicate',
    'customer',
    'date',
    'time',
    'table',
    'token',
    'order',
    'cashier',
    'counter',
    'address',
    // Invoice header labels.
    'dated',
    'mode',
    'terms',
    'reference',
    'delivery',
    'dispatch',
    'dispatched',
    'destination',
    'buyer',
    'consignee',
    'recipient',
    'state',
    'code',
  ];

  static String? _merchant(List<String> rows) {
    for (final row in rows.take(10)) {
      // Each printed column on its own: two-column invoices put the seller
      // and form labels ("Delivery Note") on the same line.
      for (final segment in row.split(RegExp(r'\s{2,}'))) {
        // "(from 1-Apr-2021)", "(Prop.)": notes, not the name.
        // "CALICUT TYRES (from" when the date went to the next column.
        final text = segment
            .replaceAll(RegExp(r'\([^)]*(?:\)|$)'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        final lower = text.toLowerCase();
        if (text.length < 3 || text.length > 40) continue;
        if (_hasWord(lower, _notMerchant)) continue;
        // Addresses carry a PIN / ZIP code.
        if (RegExp(r'\b\d{5,6}\b').hasMatch(text)) continue;
        final letters = RegExp('[A-Za-z]').allMatches(text).length;
        if (letters < 3 || letters / text.length < 0.6) continue;
        final name = _tidyName(text);
        if (name.length >= 3) return name;
      }
    }
    return null;
  }

  /// `RELIANCE FRESH` → `Reliance Fresh`. Mixed case is kept as printed.
  static String _tidyName(String text) {
    final trimmed = text.replaceAll(
      RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9.)]+$'),
      '',
    );
    if (trimmed != trimmed.toUpperCase()) return trimmed;
    return trimmed
        .split(' ')
        .map((word) {
          if (word.length <= 1) return word;
          // Keep short all-letter acronyms (LLP, KFC) as they are.
          if (word.length <= 3 && !word.contains('.')) return word;
          return '${word[0]}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  // --- Seller address --------------------------------------------------------

  /// A line of the seller's block that is not its address: contact, tax
  /// and form labels.
  static final RegExp _notAddress = RegExp(
    r'\b(gstin|gst|uin|pan|fssai|cin|mob|mobile|ph|phone|tel|e-?mail|www|'
    r'state name|state code|buyer|bill to)\b|@',
    caseSensitive: false,
  );

  /// Invoice form labels printed in the next column.
  static final RegExp _formLabel = RegExp(
    r'\b(invoice|dated?|delivery|note|reference|mode|terms|payment|order|'
    r'dispatch(?:ed)?|destination|other|vehicle|e-?way)\b',
    caseSensitive: false,
  );

  /// The seller's address: the lines under the shop's name, in its column,
  /// up to its phone, GSTIN or email ("THONDAYAD BYPASS ROAD, NEAR
  /// AZHATHRIKOVIL VISHNU TEMPLE, NELLIKODE(PO),CALICUT.673016").
  static String? _address(List<String> rows) {
    final name = _merchant(rows);
    if (name == null) return null;
    final at = rows
        .take(10)
        .toList()
        .indexWhere(
          (row) =>
              _tidyName(
                row
                    .split(RegExp(r'\s{2,}'))
                    .first
                    .replaceAll(
                      RegExp(r'\([^)]*(?:\)|$)'),
                      ' ',
                    )
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim(),
              ) ==
              name,
        );
    if (at < 0) return null;
    final parts = <String>[];
    for (final row in rows.skip(at + 1).take(5)) {
      // The shop's column: from the left, up to a form label or a bill
      // number in the next column ("THONDAYAD BYPASS  ROAD  Delivery Note").
      final segments = <String>[];
      for (final segment in row.split(RegExp(r'\s{2,}'))) {
        final text = segment.trim();
        if (text.isEmpty ||
            _formLabel.hasMatch(text) ||
            !RegExp('[A-Za-z]').hasMatch(text) ||
            // A code in the next column ("HAM8769/26-27"), not more street.
            (segments.isNotEmpty &&
                !text.contains(' ') &&
                RegExp(r'\d').hasMatch(text))) {
          break;
        }
        segments.add(text);
      }
      final text = segments.join(' ');
      if (_notAddress.hasMatch(text)) break;
      // Phone numbers alone ("0495-2361356, 2361678") end it too; a
      // garbled scrap ("L673016") is skipped.
      if (text.isEmpty) {
        if (RegExp(r'\d{8}|\d{4,}-\d{6,}').hasMatch(row)) break;
        continue;
      }
      if (!RegExp('[A-Za-z]{3,}').hasMatch(text)) continue;
      parts.add(text);
    }
    if (parts.isEmpty) return null;
    final address = parts.join(', ');
    return address.length > 160 ? address.substring(0, 160) : address;
  }

  // --- Bill number -----------------------------------------------------------

  static final RegExp _referencePattern = RegExp(
    r'\b(?:bill|invoice|inv|receipt|rcpt|order|txn)\s*'
    r'(?:no|number|num|id)?\s*[.:#\-]*\s*'
    r'([A-Za-z0-9][A-Za-z0-9\-/]{0,30})',
    caseSensitive: false,
  );

  static final RegExp _referenceLabelOnly = RegExp(
    r'^(?:bill|invoice|inv|receipt|rcpt)\s*(?:no|number|num|#)\.?:?$',
    caseSensitive: false,
  );

  static String? _reference(List<String> rows) {
    for (var i = 0; i < rows.length; i++) {
      for (final match in _referencePattern.allMatches(rows[i])) {
        final value = _referenceValue(match.group(1)!);
        if (value != null) return value;
      }
      // "Invoice No." with the number below it (form layouts); the shop's
      // name may sit between them in the next column.
      final labelled = rows[i]
          .split(RegExp(r'\s{2,}'))
          .any((segment) => _referenceLabelOnly.hasMatch(segment.trim()));
      if (!labelled) continue;
      for (final row in rows.skip(i + 1).take(2)) {
        for (final segment in row.split(RegExp(r'\s{2,}'))) {
          final below = segment.trim();
          if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-/]{0,30}$').hasMatch(below)) {
            continue;
          }
          if (_referenceValue(below) case final value?) return value;
        }
      }
    }
    return null;
  }

  /// [value] as a bill number: it has a digit and holds no calendar date
  /// ("HAM8769/26-27" is a number, "12/03/2024" a date).
  static String? _referenceValue(String value) {
    if (!RegExp(r'\d').hasMatch(value)) return null;
    // Any real day, past or future.
    final now = DateTime(2100);
    if (_datesIn(value, now: now, dayFirst: true).isNotEmpty ||
        _datesIn(value, now: now, dayFirst: false).isNotEmpty) {
      return null;
    }
    return value.length > TransactionDraft.maxReferenceLength
        ? value.substring(0, TransactionDraft.maxReferenceLength)
        : value;
  }

  // --- Seller details --------------------------------------------------------

  /// Each printed column on its own line, so a value never runs into the
  /// next column.
  static String _columns(List<String> rows) =>
      rows.expand((row) => row.split(RegExp(r'\s{2,}'))).join('\n');

  /// The seller's GSTIN, only when its check character proves it right.
  ///
  /// The layout is fixed (state digits, PAN letters and digits, "Z", check
  /// character), so look-alike misreads (O/0, I/1, S/5, B/8, Z/2) are put
  /// right by position first; a stray space is dropped. A digit misread as
  /// another ("6361" for "5361") is put right from the PAN printed on the
  /// invoice, which the GSTIN contains.
  static String? _gstin(List<String> rows, {String? pan}) {
    final match = RegExp(
      // "GSTIN/UIN", or its slash misread ("GSTINrUIN").
      r'GSTIN(?:\s*[/|rlI1]?\s*UIN)?\s*(?:no\.?)?\s*[:\-]?\s*'
      r'([0-9A-Z](?: ?[0-9A-Z]){14})\b',
      caseSensitive: false,
    ).firstMatch(_columns(rows));
    final read = match?.group(1)!.replaceAll(' ', '').toUpperCase();
    if (read == null) return null;
    const asDigit = {
      'O': '0', 'D': '0', 'I': '1', 'L': '1', 'Z': '2', 'S': '5', 'B': '8', //
    };
    const asLetter = {'0': 'O', '1': 'I', '2': 'Z', '5': 'S', '8': 'B'};
    const digitAt = {0, 1, 7, 8, 9, 10};
    const letterAt = {2, 3, 4, 5, 6, 11, 13};
    final fixed = [
      for (final (i, char) in read.split('').indexed)
        i == 13
            ? 'Z'
            : digitAt.contains(i)
            ? asDigit[char] ?? char
            : letterAt.contains(i)
            ? asLetter[char] ?? char
            : char,
    ];
    if (_gstinValid(fixed.join())) return fixed.join();
    // Positions 12 and 14 may be a digit or a letter: try the look-alike.
    const swap = {
      '0': 'O', 'O': '0', '1': 'I', 'I': '1', '5': 'S', 'S': '5', //
      '8': 'B', 'B': '8', '2': 'Z', 'Z': '2',
    };
    for (final i in const [12, 14]) {
      final other = swap[fixed[i]];
      if (other == null) continue;
      final tried = [...fixed]..[i] = other;
      if (_gstinValid(tried.join())) return tried.join();
    }
    return _gstinFromPan(fixed, pan);
  }

  /// [gstin] with its PAN part (characters 3–12) checked against [pan]:
  /// where they differ, either may be the misread one. Kept only when
  /// exactly one choice passes the check character.
  static String? _gstinFromPan(List<String> gstin, String? pan) {
    if (pan == null || gstin.length != 15) return null;
    final differ = [
      for (var i = 0; i < 10; i++)
        if (gstin[i + 2] != pan[i]) i + 2,
    ];
    if (differ.isEmpty || differ.length > 3) return null;
    final valid = <String>{};
    for (var mask = 1; mask < 1 << differ.length; mask++) {
      final tried = [...gstin];
      for (final (bit, i) in differ.indexed) {
        if (mask & (1 << bit) != 0) tried[i] = pan[i - 2];
      }
      if (_gstinValid(tried.join())) valid.add(tried.join());
    }
    return valid.length == 1 ? valid.single : null;
  }

  /// The PAN printed on the invoice ("Company's PAN : AAHFC5361P"), with
  /// look-alikes put right by position (five letters, four digits, a
  /// letter).
  static String? _pan(List<String> rows) {
    final match = RegExp(
      r'\bPAN\b[^A-Za-z0-9]*([0-9A-Z](?: ?[0-9A-Z]){9})\b',
    ).firstMatch(_columns(rows));
    final read = match?.group(1)!.replaceAll(' ', '');
    if (read == null) return null;
    const asDigit = {
      'O': '0', 'D': '0', 'I': '1', 'L': '1', 'Z': '2', 'S': '5', 'B': '8', //
    };
    const asLetter = {'0': 'O', '1': 'I', '2': 'Z', '5': 'S', '8': 'B'};
    final pan = [
      for (final (i, char) in read.split('').indexed)
        i >= 5 && i <= 8 ? asDigit[char] ?? char : asLetter[char] ?? char,
    ].join();
    return RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(pan) ? pan : null;
  }

  static const String _base36 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// The GSTIN check character (Luhn mod 36 over the first 14).
  static bool _gstinValid(String gstin) {
    if (!RegExp(
      r'^\d{2}[A-Z]{5}\d{4}[A-Z][0-9A-Z]Z[0-9A-Z]$',
    ).hasMatch(gstin)) {
      return false;
    }
    var sum = 0;
    for (var i = 0; i < 14; i++) {
      final product = _base36.indexOf(gstin[i]) * (i.isEven ? 1 : 2);
      sum += product ~/ 36 + product % 36;
    }
    return gstin[14] == _base36[(36 - sum % 36) % 36];
  }

  /// A labelled number ("Mob: …"), else an Indian mobile number printed on
  /// its own line in the seller's block.
  static String? _phone(List<String> rows) {
    final columns = _columns(rows);
    final labelled = RegExp(
      r'\b(?:mob(?:ile)?|ph(?:one)?|tel|contact|cell)\.?\s*(?:no\.?)?\s*'
      r'[:\-]?\s*(\+?\d[\d \-]{7,15}\d)',
      caseSensitive: false,
    ).firstMatch(columns);
    if (labelled != null) {
      return labelled.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return RegExp(
      r'^(?:\+91[ \-]?)?[6-9]\d{9}$',
      multiLine: true,
    ).firstMatch(columns)?.group(0);
  }

  static String? _email(List<String> rows) => RegExp(
    r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
  ).firstMatch(_columns(rows))?.group(0);

  // --- Payment method --------------------------------------------------------

  static String? _paymentMethod(List<String> rows) {
    final text = rows.join('\n').toLowerCase();
    bool has(String pattern) => RegExp(pattern).hasMatch(text);
    // Most specific first: a card slip may also print "cash" as a label.
    final method = has(r'\b(upi|gpay|google pay|phonepe|phone pe|paytm|bhim)\b')
        ? 'UPI'
        : has(r'\b(card|visa|mastercard|master card|rupay|amex|maestro)\b')
        ? 'Card'
        : has(r'\bcash\b(?!\s*memo)')
        ? 'Cash'
        : null;
    return method != null && PaymentMethods.common.contains(method)
        ? method
        : null;
  }
}

/// Finds the item rows of a receipt and the rates that make them add up to
/// its total, on the device.
///
/// An item row has a quantity ("1 NOS", "2 pcs", "x2") and a description.
/// Its candidate rates are the amounts printed on it (a GST invoice prints
/// a tax-inclusive and a pre-tax rate) plus amounts a tilted photo pushed
/// onto the following line. The first combination whose lines add up
/// exactly to the total wins; failing that, pre-tax lines plus the printed
/// tax lines (SGST, CGST…) that add up to it. Nothing that does not add up
/// is returned, so a filled form always balances.
abstract final class ReceiptItems {
  static const int _maxItems = 12;
  static const int _maxCandidates = 4;

  static final RegExp _quantity = RegExp(
    r'(?<![\d.,/])(\d{1,4}(?:\.\d{1,3})?)\s*'
    // "N0S": OCR reads the O of NOS as a zero.
    '(n[o0]s|n[o0]|pcs|pc|qty|kgs?|gms?|g|ltrs?|l|ml|units?|box|set|pairs?|'
    r'mtrs?|m)\b'
    r'|\bx\s*(\d{1,4})\b|\b(\d{1,4})\s*x\b',
    caseSensitive: false,
  );
  static final RegExp _notItem = RegExp(
    r'\b(total|sub\s*total|subtotal|grand|net|taxable|amount chargeable|'
    r'description|hsn|quantity|rate|balance|tendered|change|round)\b',
    caseSensitive: false,
  );
  static final RegExp _taxRow = RegExp(
    r'\b(sgst|cgst|igst|utgst|vat|cess|service charge|gst)\b',
    caseSensitive: false,
  );

  static List<LineItem> find(
    List<String> rows, {
    required int total,
    required Currency currency,
  }) {
    var items = _namedInOrder(rows, currency) ?? <_ItemRow>[];
    if (items.isEmpty) {
      for (var i = 0; i < rows.length && items.length <= _maxItems; i++) {
        final item = _itemRow(rows, i, currency);
        if (item != null) items.add(item);
      }
    }
    // No quantity read on any row (a misread "1 NOS"): the named rows with
    // an amount between the items header and the total, one of each.
    if (items.isEmpty) items = _rowsWithoutQuantity(rows, currency);
    if (items.isEmpty || items.length > _maxItems) return const [];

    // Pre-tax items plus the GST and other tax lines printed after them,
    // so the tax shows on its own lines.
    final taxes = _taxLines(rows, currency);
    final taxSum = LineItem.total(taxes);
    final withTaxes = taxes.isNotEmpty && taxSum < total;
    if (withTaxes) {
      final preTax = _combine(items, total - taxSum);
      if (preTax != null) return [...preTax, ...taxes];
    }

    // Tax-inclusive: the items alone make the total.
    final inclusive = _combine(items, total);
    if (inclusive != null) return inclusive;

    // Nothing adds up exactly (a tax or charge not read, a misread rate):
    // the items as read, closest to the total, and a line for the rest.
    if (withTaxes) {
      final closest = _closest(items, total - taxSum);
      if (closest != null) {
        final lines = ReceiptScan.balanced(
          [...closest, ...taxes],
          total,
          currency,
        );
        if (lines.isNotEmpty) return lines;
      }
    }
    final closest = _closest(items, total);
    return closest == null
        ? const []
        : ReceiptScan.balanced(closest, total, currency);
  }

  static final RegExp _itemsHeader = RegExp(
    r'\b(description|particulars|items?|product|goods)\b',
    caseSensitive: false,
  );

  /// The items when names and amounts sit on different rows: a curved or
  /// tilted page can leave a name alone on its row and pair the next name
  /// with its amounts ("Ciutch Set" / "2 Bearing  1 Nos  5,950.00" /
  /// "4016  1 Nos  1,450.00"). The description column lists the items in
  /// the same order as the quantity rows, so names go to rows in order:
  /// only when they are as many, and some name stood alone or some row had
  /// none. `null` otherwise.
  static List<_ItemRow>? _namedInOrder(List<String> rows, Currency currency) {
    final header = rows.indexWhere(_itemsHeader.hasMatch);
    if (header < 0) return null;
    final names = <(int, String)>[];
    final itemRows = <int>[];
    var misplaced = false;
    for (var i = header + 1; i < rows.length; i++) {
      final row = rows[i];
      if (_notItem.hasMatch(row) || _taxRow.hasMatch(row)) continue;
      if (_quantity.firstMatch(row) case final match?) {
        itemRows.add(i);
        if (_nameIn(row.substring(0, match.start)) case final name?) {
          names.add((i, name));
        } else {
          misplaced = true;
        }
        continue;
      }
      final hasAmount = ReceiptParser._amount
          .allMatches(row)
          .any((match) => match.group(2) != null);
      final name = _nameIn(row);
      if (hasAmount ||
          name == null ||
          RegExp('[A-Za-z]').allMatches(name).length < 3 ||
          row.trimLeft().startsWith('(') ||
          RegExp(r'\b(tax|incl|excl)\b', caseSensitive: false).hasMatch(row)) {
        continue;
      }
      names.add((i, name));
      misplaced = true;
    }
    if (itemRows.isEmpty || !misplaced) return null;
    // Names below the last item row are notes, not items.
    final listed = [
      for (final (i, name) in names)
        if (i <= itemRows.last) name,
    ];
    if (listed.length != itemRows.length || listed.length > _maxItems) {
      return null;
    }
    final items = [
      for (final (k, i) in itemRows.indexed)
        _itemRow(rows, i, currency, name: listed[k]),
    ];
    return items.contains(null) ? null : items.cast<_ItemRow>();
  }

  /// The item name in [text]: its words, without the serial number, HSN
  /// code and other bare numbers. `null` when it has none.
  static String? _nameIn(String text) {
    final segments = text
        .split(RegExp(r'\s{2,}'))
        .map((segment) => segment.trim())
        .where((segment) => RegExp('[A-Za-z]{2,}').hasMatch(segment))
        .toList();
    if (segments.isEmpty) return null;
    return segments
        .join(' ')
        // "1 Clutch Set", or "1Clutch Set" read without the space; not
        // "5W30 Oil".
        .replaceFirst(
          RegExp(r'^\d{1,3}(?:[.)]?\s+(?=\S)|(?=[A-Z][a-z]))'),
          '',
        );
  }

  static List<_ItemRow> _rowsWithoutQuantity(
    List<String> rows,
    Currency currency,
  ) {
    final header = rows.indexWhere(_itemsHeader.hasMatch);
    if (header < 0) return const [];
    final items = <_ItemRow>[];
    for (var i = header + 1; i < rows.length; i++) {
      if (RegExp(r'\btotal\b', caseSensitive: false).hasMatch(rows[i])) {
        break;
      }
      final item = _itemRow(rows, i, currency, withoutQuantity: true);
      // A name of a few letters ("RTT") is a wrapped line, not an item.
      if (item == null ||
          RegExp('[A-Za-z]').allMatches(item.description).length < 4) {
        continue;
      }
      items.add(item);
      if (items.length > _maxItems) return const [];
    }
    return items;
  }

  /// The item on row [i]: its name, quantity and the amounts that may be
  /// its rate. [withoutQuantity]: rows with no quantity count as one, the
  /// name being the text before the first amount.
  static _ItemRow? _itemRow(
    List<String> rows,
    int i,
    Currency currency, {
    bool withoutQuantity = false,
    String? name,
  }) {
    final row = rows[i];
    if (_notItem.hasMatch(row) || _taxRow.hasMatch(row)) return null;
    final int read;
    final int nameEnd;
    final int amountsStart;
    if (_quantity.firstMatch(row) case final match?) {
      final quantityText = match.group(1) ?? match.group(3) ?? match.group(4)!;
      final quantity = Money.parseQuantityMilli(quantityText);
      if (quantity == null || quantity == 0) return null;
      read = quantity;
      nameEnd = match.start;
      amountsStart = match.end;
    } else if (withoutQuantity) {
      final first = ReceiptParser._amount
          .allMatches(row)
          .where((match) => match.group(2) != null)
          .firstOrNull;
      if (first == null) return null;
      read = 1000;
      nameEnd = first.start;
      amountsStart = first.start;
    } else {
      return null;
    }

    // Description: the text before the quantity, unless the name was
    // found on another row.
    final itemName = name ?? _nameIn(row.substring(0, nameEnd));
    if (itemName == null) return null;
    var description = itemName;

    // In print order, repeats kept: "2,148.44 … 2,148.44" is rate and
    // amount of one unit.
    final printed = <int>[];
    void addAmounts(String text) {
      for (final match in ReceiptParser._amount.allMatches(text)) {
        if (match.group(2) == null) continue;
        final value = ReceiptParser._toMinor(match, currency);
        if (value != null && value > 0) printed.add(value);
      }
    }

    addAmounts(row.substring(amountsStart));
    // The next line: a wrapped name ("RTT") and amounts the tilt moved
    // there, unless it is an item, total or tax line itself.
    if (i + 1 < rows.length) {
      final next = rows[i + 1];
      final nextIsOther =
          _quantity.hasMatch(next) ||
          _notItem.hasMatch(next) ||
          _taxRow.hasMatch(next);
      if (!nextIsOther) {
        final words = next.split(RegExp(r'\s{2,}')).first.trim();
        if (name == null &&
            RegExp(r'^[A-Za-z][A-Za-z0-9 .\-/]{0,24}$').hasMatch(words)) {
          description = '$description $words';
        }
        addAmounts(next);
      }
    }
    if (printed.isEmpty) return null;
    final amounts = printed.toSet().toList();
    final quantity = _checkedQuantity(read, printed);

    // Each amount as the unit rate, or as the line amount for the quantity.
    final candidates = <int>[];
    for (final amount in amounts) {
      if (!candidates.contains(amount)) candidates.add(amount);
      if (quantity != 1000) {
        final rate = (amount * 1000) ~/ quantity;
        if (Money.lineAmount(quantityMilli: quantity, rateMinor: rate) ==
                amount &&
            !candidates.contains(rate)) {
          candidates.add(rate);
        }
      }
    }
    return _ItemRow(
      description: description.length > LineItem.maxDescriptionLength
          ? description.substring(0, LineItem.maxDescriptionLength)
          : description,
      quantityMilli: quantity,
      rates: candidates.take(_maxCandidates).toList(),
    );
  }

  /// The quantity as read, unless the row's own amounts disprove it: when
  /// no rate × quantity gives another printed amount but exactly one whole
  /// quantity does, OCR misread it ("4 NOS" for "1 NOS" beside a rate and
  /// amount that are equal).
  static int _checkedQuantity(int read, List<int> printed) {
    bool fits(int quantity) {
      for (final (i, rate) in printed.indexed) {
        for (final (j, amount) in printed.indexed) {
          if (i != j &&
              Money.lineAmount(quantityMilli: quantity, rateMinor: rate) ==
                  amount) {
            return true;
          }
        }
      }
      return false;
    }

    if (printed.length < 2 || fits(read)) return read;
    final whole = <int>{
      for (final (i, rate) in printed.indexed)
        for (final (j, amount) in printed.indexed)
          if (i != j && amount % rate == 0 && amount ~/ rate <= 9999)
            amount ~/ rate * 1000,
    };
    return whole.length == 1 ? whole.single : read;
  }

  /// The first choice of one rate per item whose lines add up to [target].
  static List<LineItem>? _combine(List<_ItemRow> items, int target) {
    final chosen = List<int>.filled(items.length, 0);
    bool search(int index, int sum) {
      if (index == items.length) return sum == target;
      final item = items[index];
      for (final rate in item.rates) {
        final amount = Money.lineAmount(
          quantityMilli: item.quantityMilli,
          rateMinor: rate,
        );
        if (sum + amount > target) continue;
        chosen[index] = rate;
        if (search(index + 1, sum + amount)) return true;
      }
      return false;
    }

    if (!search(0, 0)) return null;
    return [
      for (final (i, item) in items.indexed)
        LineItem.of(
          description: item.description,
          quantityMilli: item.quantityMilli,
          rateMinor: chosen[i],
        ),
    ];
  }

  /// The row's last amount printed with decimals: a tax amount, never its
  /// rate.
  static int? _decimalAmount(String row, Currency currency) {
    final match = ReceiptParser._amount
        .allMatches(row)
        .where((match) => match.group(2) != null)
        .lastOrNull;
    return match == null ? null : ReceiptParser._toMinor(match, currency);
  }

  /// "OUTPUT SGST (@14%" → "SGST 14%"; other tax rows as printed.
  static String _taxLabel(String row) {
    final rated = RegExp(
      r'\b(sgst|cgst|igst|utgst|gst|vat|cess)\b[^\d%]{0,5}'
      r'(\d{1,2}(?:\.\d{1,2})?)\s*%',
      caseSensitive: false,
    ).firstMatch(row);
    if (rated != null) {
      return '${rated.group(1)!.toUpperCase()} ${rated.group(2)}%';
    }
    return row
        .split(RegExp(r'\s{2,}'))
        .first
        .replaceFirst(RegExp(r'^output\s+', caseSensitive: false), '')
        .trim();
  }

  /// The choice of one rate per item whose lines come closest to [target]
  /// without passing it, or `null` when even the smallest pass it.
  static List<LineItem>? _closest(List<_ItemRow> items, int target) {
    int amount(_ItemRow item, int rate) =>
        Money.lineAmount(quantityMilli: item.quantityMilli, rateMinor: rate);
    // The most each item can add, for pruning.
    final most = [
      for (final item in items)
        item.rates.map((rate) => amount(item, rate)).reduce(max),
    ];
    final mostAfter = List<int>.filled(items.length + 1, 0);
    for (var i = items.length - 1; i >= 0; i--) {
      mostAfter[i] = mostAfter[i + 1] + most[i];
    }

    final chosen = List<int>.filled(items.length, 0);
    List<int>? best;
    var bestSum = -1;
    void search(int index, int sum) {
      if (bestSum == target || sum + mostAfter[index] <= bestSum) return;
      if (index == items.length) {
        bestSum = sum;
        best = [...chosen];
        return;
      }
      final item = items[index];
      for (final rate in item.rates) {
        final next = sum + amount(item, rate);
        if (next > target) continue;
        chosen[index] = rate;
        search(index + 1, next);
      }
    }

    search(0, 0);
    final rates = best;
    if (rates == null) return null;
    return [
      for (final (i, item) in items.indexed)
        LineItem.of(
          description: item.description,
          quantityMilli: item.quantityMilli,
          rateMinor: rates[i],
        ),
    ];
  }

  static List<LineItem> _taxLines(List<String> rows, Currency currency) {
    final lines = <LineItem>[];
    // Rows whose amount is taken, so a stray one goes to one tax only.
    final used = <int>{};
    for (final (i, row) in rows.indexed) {
      if (!_taxRow.hasMatch(row) || _notItem.hasMatch(row)) continue;
      var amount = _decimalAmount(row, currency);
      if (amount != null) {
        used.add(i);
      } else {
        // A tilt can move the amount up to two rows away, alone on its
        // row. A wrong pick can't stick: the lines must still add up to
        // the total exactly.
        for (final j in [i + 1, i - 1, i + 2, i - 2]) {
          if (j < 0 || j >= rows.length || used.contains(j)) continue;
          if (RegExp('[A-Za-z]').hasMatch(rows[j])) continue;
          amount = _decimalAmount(rows[j], currency);
          if (amount != null) {
            used.add(j);
            break;
          }
        }
      }
      if (amount == null || amount == 0) continue;
      lines.add(LineItem.of(description: _taxLabel(row), rateMinor: amount));
    }
    // A round-off added to the bill, up to one major unit. One taken off
    // ("-0.02") can't be a line of its own.
    for (final row in rows) {
      final match = RegExp(
        r'^round(?:ed)?[\s\-]*(?:off|ing)?\b(.*)$',
        caseSensitive: false,
      ).firstMatch(row);
      if (match == null || match.group(1)!.contains('-')) continue;
      final amount = ReceiptParser._lastAmount(match.group(1)!, currency);
      if (amount == null || amount == 0) continue;
      if (amount > pow(10, currency.decimals)) continue;
      lines.add(LineItem.of(description: 'Round off', rateMinor: amount));
      break;
    }
    return lines;
  }
}

class _ItemRow {
  const _ItemRow({
    required this.description,
    required this.quantityMilli,
    required this.rates,
  });

  final String description;
  final int quantityMilli;
  final List<int> rates;
}
