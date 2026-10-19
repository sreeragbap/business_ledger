import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/business/domain/const/time_zones.dart';
import 'package:equatable/equatable.dart';

/// A `businesses` row (`supabase/README.md`). Created only by the
/// `create_business` RPC; clients may update [name], [description],
/// [timezone] and [settings] (admin+) or [archived] (owner) — row level
/// security and column privileges enforce it.
class Business extends Equatable {
  const Business({
    required this.id,
    required this.name,
    this.description = '',
    this.currency = Currency.inr,
    this.timezone = TimeZones.fallback,
    this.template = BusinessTemplate.blank,
    this.ownerId = '',
    this.settings = const BusinessSettings(),
    this.archived = false,
    this.createdAt,
    this.updatedAt,
  });

  /// A Postgres row (snake_case; the currency is three columns).
  factory Business.fromRow(Map<String, dynamic> row) => Business.fromMap(
    row.readString('id'),
    {
      ...RowKeys.camelMap(row),
      'currency': {
        'code': row['currency_code'],
        'decimals': row['currency_decimals'],
        'symbol': row['currency_symbol'],
      },
    },
  );

  factory Business.fromMap(String id, Map<String, dynamic> map) {
    final currencyMap = map.readMap('currency');
    return Business(
      id: id,
      name: map.readString('name'),
      description: map.readString('description'),
      currency: _currency(currencyMap),
      timezone: map.readOptionalString('timezone') ?? TimeZones.fallback,
      template: BusinessTemplate.fromKey(map['template']),
      ownerId: map.readString('ownerId'),
      settings: BusinessSettings.fromMap(map.readMap('settings')),
      archived: map.readBool('archived'),
      createdAt: map.readDate('createdAt'),
      updatedAt: map.readDate('updatedAt'),
    );
  }

  final String id;
  final String name;
  final String description;

  /// Fixed at creation: changing decimals would rescale every amount.
  final Currency currency;

  /// IANA name; decides which calendar day "today" is.
  final String timezone;
  final BusinessTemplate template;
  final String ownerId;
  final BusinessSettings settings;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The stored currency as written by the server. A currency this app
  /// does not list is still honoured as stored (its decimals are what the
  /// amounts were written with); a malformed one falls back to INR.
  static Currency _currency(Map<String, dynamic> map) {
    final code = map.readOptionalString('code');
    final decimals = map.readOptionalInt('decimals');
    if (code == null || decimals == null || decimals < 0 || decimals > 4) {
      return code == null ? Currency.inr : Currency.byCode(code);
    }
    return Currency(
      code: code,
      decimals: decimals,
      symbol: map.readOptionalString('symbol') ?? '$code ',
    );
  }

  /// Short form for avatars: up to two initials.
  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final value = words.map((word) => word[0].toUpperCase()).join();
    return value.isEmpty ? '?' : value;
  }

  bool isEnabled(StandardField field) => settings.isEnabled(field);

  /// The columns a client may change, as a row update. [settings] is
  /// merged over [storedSettings] (the row's current `settings`), so keys
  /// this version does not know survive.
  static Map<String, Object?> detailsUpdate({
    required String name,
    required String description,
    required String timezone,
    required BusinessSettings settings,
    Map<String, dynamic> storedSettings = const {},
  }) => {
    'name': name.trim(),
    'description': description.trim(),
    'timezone': timezone,
    'settings': {...storedSettings, ...settings.toMap()},
  };

  Business copyWith({
    String? name,
    String? description,
    String? timezone,
    BusinessSettings? settings,
    bool? archived,
  }) => Business(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    currency: currency,
    timezone: timezone ?? this.timezone,
    template: template,
    ownerId: ownerId,
    settings: settings ?? this.settings,
    archived: archived ?? this.archived,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    currency,
    timezone,
    template,
    ownerId,
    settings,
    archived,
    createdAt,
    updatedAt,
  ];
}

/// `businesses.settings` (jsonb, camelCase keys).
class BusinessSettings extends Equatable {
  const BusinessSettings({
    this.enabledStandardFieldKeys = const [],
    this.invoicePrefix = defaultInvoicePrefix,
    this.billPrefix = defaultBillPrefix,
    this.receiptPrefix = defaultReceiptPrefix,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxId = '',
  });

  factory BusinessSettings.fromMap(Map<String, dynamic> map) =>
      BusinessSettings(
        enabledStandardFieldKeys: map.readStringList('enabledStandardFields'),
        invoicePrefix:
            map.readOptionalString('invoicePrefix') ?? defaultInvoicePrefix,
        billPrefix: map.readOptionalString('billPrefix') ?? defaultBillPrefix,
        receiptPrefix:
            map.readOptionalString('receiptPrefix') ?? defaultReceiptPrefix,
        address: map.readString('address'),
        phone: map.readString('phone'),
        email: map.readString('email'),
        taxId: map.readString('taxId'),
      );

  static const String defaultInvoicePrefix = 'INV';
  static const String defaultBillPrefix = 'BILL';
  static const String defaultReceiptPrefix = 'RCPT';

  /// Raw keys as stored, unknown ones included, so toggling a known field
  /// never drops a key a newer app version added.
  final List<String> enabledStandardFieldKeys;
  final String invoicePrefix;
  final String billPrefix;
  final String receiptPrefix;
  final String address;
  final String phone;
  final String email;
  final String taxId;

  Set<StandardField> get enabledStandardFields => {
    for (final key in enabledStandardFieldKeys) ?StandardField.fromKey(key),
  };

  bool isEnabled(StandardField field) =>
      enabledStandardFieldKeys.contains(field.key);

  BusinessSettings toggle(StandardField field, {required bool enabled}) {
    final keys = [...enabledStandardFieldKeys]..remove(field.key);
    if (enabled) keys.add(field.key);
    return copyWith(enabledStandardFieldKeys: keys);
  }

  Map<String, Object?> toMap() => {
    'enabledStandardFields': enabledStandardFieldKeys,
    'invoicePrefix': invoicePrefix.trim(),
    'billPrefix': billPrefix.trim(),
    'receiptPrefix': receiptPrefix.trim(),
    'address': address.trim(),
    'phone': phone.trim(),
    'email': email.trim(),
    'taxId': taxId.trim(),
  };

  BusinessSettings copyWith({
    List<String>? enabledStandardFieldKeys,
    String? invoicePrefix,
    String? billPrefix,
    String? receiptPrefix,
    String? address,
    String? phone,
    String? email,
    String? taxId,
  }) => BusinessSettings(
    enabledStandardFieldKeys:
        enabledStandardFieldKeys ?? this.enabledStandardFieldKeys,
    invoicePrefix: invoicePrefix ?? this.invoicePrefix,
    billPrefix: billPrefix ?? this.billPrefix,
    receiptPrefix: receiptPrefix ?? this.receiptPrefix,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    taxId: taxId ?? this.taxId,
  );

  @override
  List<Object?> get props => [
    enabledStandardFieldKeys,
    invoicePrefix,
    billPrefix,
    receiptPrefix,
    address,
    phone,
    email,
    taxId,
  ];
}
