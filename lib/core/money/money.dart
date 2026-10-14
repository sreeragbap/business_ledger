import 'package:business_ledger/core/money/currency.dart';
import 'package:intl/intl.dart';

/// Integer minor-unit arithmetic for one [Currency].
///
/// Every stored and computed amount in the app is an `int` of minor units
/// (paise, cents). `double` is used only to *display* a value, never to hold
/// one: 0.1 + 0.2 != 0.3 is not a bug a ledger can afford.
abstract final class Money {
  /// Largest amount accepted from input: 10^13 minor units (100 billion in a
  /// 2-decimal currency). Far beyond any real entry, and well inside the
  /// 2^53 range where JavaScript (Cloud Functions) still counts exactly.
  static const int maxMinor = 10000000000000;

  /// Parses user input such as `1,250.5` into minor units, or `null` when it
  /// is not a valid non-negative amount for [currency].
  ///
  /// Strict on purpose: more fraction digits than the currency has is an
  /// error rather than a silent rounding, so what the user typed is exactly
  /// what is stored.
  static int? parse(String input, Currency currency) {
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(cleaned);
    if (match == null) return null;

    final whole = match.group(1)!;
    final fraction = match.group(2) ?? '';
    if (fraction.length > currency.decimals) return null;

    final padded = fraction.padRight(currency.decimals, '0');
    final digits = '$whole$padded'.replaceFirst(RegExp('^0+(?=.)'), '');
    // Bounded before int.parse so an absurd paste cannot overflow.
    if (digits.length > maxMinor.toString().length) return null;
    final value = int.parse(digits);
    return value > maxMinor ? null : value;
  }

  /// `125050` → `1,250.50` (no symbol). For editable fields.
  static String plain(int minor, Currency currency) {
    final negative = minor < 0;
    final digits = minor.abs().toString().padLeft(currency.decimals + 1, '0');
    final split = digits.length - currency.decimals;
    final whole = NumberFormat.decimalPattern(
      'en_US',
    ).format(int.parse(digits.substring(0, split)));
    final fraction = currency.decimals == 0 ? '' : '.${digits.substring(split)}';
    return '${negative ? '-' : ''}$whole$fraction';
  }

  /// `125050` → `₹1,250.50`, `-5000` → `-₹50.00`.
  static String format(int minor, Currency currency) {
    final sign = minor < 0 ? '-' : '';
    return '$sign${currency.symbol}${plain(minor.abs(), currency)}';
  }

  /// `12500000` → `₹1.3L`-style compact figure for dashboard tiles.
  static String compact(int minor, Currency currency) {
    final major = minor / _scale(currency.decimals);
    final text = NumberFormat.compact(locale: 'en_US').format(major.abs());
    return '${minor < 0 ? '-' : ''}${currency.symbol}$text';
  }

  /// quantity (thousandths) × rate (minor units), rounded half away from
  /// zero to a whole minor unit. One rounding per line; totals are sums of
  /// already-rounded lines so the printed lines always add up.
  static int lineAmount({required int quantityMilli, required int rateMinor}) {
    final product = quantityMilli * rateMinor;
    final rounded = (product.abs() + 500) ~/ 1000;
    return product < 0 ? -rounded : rounded;
  }

  /// Parses a quantity like `2.5` into thousandths (`2500`).
  static int? parseQuantityMilli(String input) =>
      parse(input, const Currency(code: 'QTY', decimals: 3, symbol: ''));

  /// `2500` → `2.5`. Trailing zeros dropped.
  static String quantity(int milli) {
    final whole = milli ~/ 1000;
    final fraction = (milli % 1000).toString().padLeft(3, '0');
    final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? '$whole' : '$whole.$trimmed';
  }

  static int _scale(int decimals) {
    var scale = 1;
    for (var i = 0; i < decimals; i++) {
      scale *= 10;
    }
    return scale;
  }
}
