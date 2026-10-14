import 'package:equatable/equatable.dart';

/// A business's currency: what [Money] is denominated in.
///
/// [decimals] is the number of minor-unit digits (2 for USD and INR, 0 for
/// JPY, 3 for KWD). It is fixed when the business is created: changing it
/// later would silently rescale every stored amount.
class Currency extends Equatable {
  const Currency({
    required this.code,
    required this.decimals,
    required this.symbol,
  });

  factory Currency.fromMap(Map<String, dynamic> map) => Currency(
    code: map['code'] as String,
    decimals: (map['decimals'] as num).toInt(),
    symbol: map['symbol'] as String,
  );

  /// The default for new businesses, and the fallback in tests.
  static const Currency inr = Currency(code: 'INR', decimals: 2, symbol: '₹');

  /// The currencies offered when creating a business. Deliberately short:
  /// each one is a promise about [decimals] that must hold.
  static const List<Currency> supported = <Currency>[
    inr,
    Currency(code: 'USD', decimals: 2, symbol: r'$'),
    Currency(code: 'EUR', decimals: 2, symbol: '€'),
    Currency(code: 'GBP', decimals: 2, symbol: '£'),
    Currency(code: 'AED', decimals: 2, symbol: 'AED '),
    Currency(code: 'SAR', decimals: 2, symbol: 'SAR '),
    Currency(code: 'JPY', decimals: 0, symbol: '¥'),
    Currency(code: 'KWD', decimals: 3, symbol: 'KWD '),
  ];

  static Currency byCode(String code) => supported.firstWhere(
    (currency) => currency.code == code,
    orElse: () => inr,
  );

  final String code;
  final int decimals;
  final String symbol;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'code': code,
    'decimals': decimals,
    'symbol': symbol,
  };

  @override
  List<Object?> get props => <Object?>[code, decimals, symbol];
}
