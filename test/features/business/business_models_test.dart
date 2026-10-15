import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/business/domain/const/business_template.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/business/domain/const/time_zones.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/create_business_request.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime.utc(2026, 3, 1, 9, 30);

  /// A business document as `createBusiness` writes it.
  Map<String, dynamic> seeded() => {
    'name': 'Rao Constructions',
    'description': 'Villas',
    'currency': {'code': 'KWD', 'decimals': 3, 'symbol': 'KWD '},
    'timezone': 'Asia/Kuwait',
    'template': 'construction',
    'ownerId': 'u1',
    'memberUids': ['u1', 'u2'],
    'settings': {
      'enabledStandardFields': ['party', 'lineItems', 'project'],
      'invoicePrefix': 'RC',
      'billPrefix': 'BILL',
      'receiptPrefix': 'RCPT',
      'address': 'Kochi',
      'phone': '+91 90000 00000',
      'email': 'a@example.com',
      'taxId': '32ABCDE1234F1Z5',
    },
    'archived': false,
    'createdAt': Timestamp.fromDate(created),
    'updatedAt': Timestamp.fromDate(created),
  };

  group('Business.fromMap', () {
    test('reads every field written by createBusiness', () {
      final business = Business.fromMap('b1', seeded());
      expect(business.id, 'b1');
      expect(business.name, 'Rao Constructions');
      expect(
        business.currency,
        const Currency(code: 'KWD', decimals: 3, symbol: 'KWD '),
      );
      expect(business.timezone, 'Asia/Kuwait');
      expect(business.template, BusinessTemplate.construction);
      expect(business.memberUids, ['u1', 'u2']);
      expect(business.settings.invoicePrefix, 'RC');
      expect(business.settings.taxId, '32ABCDE1234F1Z5');
      expect(business.isEnabled(StandardField.project), isTrue);
      expect(business.isEnabled(StandardField.dueDate), isFalse);
      expect(business.createdAt, created.toLocal());
    });

    test('missing and mistyped fields fall back safely', () {
      final business = Business.fromMap('b1', const {
        'name': 42,
        'currency': 'INR',
        'memberUids': ['u1', 3, null],
        'settings': {'enabledStandardFields': 'party'},
        'archived': 'yes',
        'createdAt': 'yesterday',
      });
      expect(business.name, '');
      expect(business.currency, Currency.inr);
      expect(business.timezone, TimeZones.fallback);
      expect(business.template, BusinessTemplate.blank);
      expect(business.memberUids, ['u1']);
      expect(business.settings.enabledStandardFieldKeys, isEmpty);
      expect(business.settings.invoicePrefix, 'INV');
      expect(business.archived, isFalse);
      expect(business.createdAt, isNull);
    });

    test('a pending server timestamp reads as null', () {
      final map = seeded()..['updatedAt'] = null;
      expect(Business.fromMap('b1', map).updatedAt, isNull);
    });

    test('an integral double still reads as an int, a fraction does not', () {
      final map = seeded()
        ..['currency'] = {'code': 'USD', 'decimals': 2.0, 'symbol': r'$'};
      expect(Business.fromMap('b1', map).currency.decimals, 2);
      map['currency'] = {'code': 'USD', 'decimals': 2.5};
      // Malformed decimals: fall back to the listed currency for the code.
      expect(
        Business.fromMap('b1', map).currency,
        Currency.byCode('USD'),
      );
    });
  });

  group('BusinessSettings', () {
    test('round-trips through toMap', () {
      final settings = Business.fromMap('b1', seeded()).settings;
      expect(BusinessSettings.fromMap(settings.toMap()), settings);
    });

    test('toggling a field keeps keys this version does not know', () {
      const settings = BusinessSettings(
        enabledStandardFieldKeys: ['party', 'futureThing'],
      );
      final on = settings.toggle(StandardField.notes, enabled: true);
      expect(on.enabledStandardFieldKeys, ['party', 'futureThing', 'notes']);
      final off = on.toggle(StandardField.party, enabled: false);
      expect(off.enabledStandardFieldKeys, ['futureThing', 'notes']);
      expect(off.enabledStandardFields, {StandardField.notes});
    });
  });

  test('detailsUpdate writes only rule-allowed keys, settings by path', () {
    final update = Business.detailsUpdate(
      name: '  New name ',
      description: 'd',
      timezone: 'Asia/Dubai',
      settings: const BusinessSettings(invoicePrefix: 'X'),
    );
    final topLevel = update.keys.map((key) => key.split('.').first).toSet();
    expect(topLevel, {'name', 'description', 'timezone', 'settings'});
    expect(update['name'], 'New name');
    expect(update['settings.invoicePrefix'], 'X');
    expect(update.containsKey('settings'), isFalse);
  });

  group('Member', () {
    test('round-trips through toMap', () {
      const member = Member(
        uid: 'u2',
        role: Role.editor,
        email: 'e@example.com',
        displayName: 'Esha',
        addedBy: 'u1',
      );
      expect(Member.fromMap('u2', member.toMap()), member);
    });

    test('an unknown role reads as viewer', () {
      expect(
        Member.fromMap('u', const {'role': 'superuser'}).role,
        Role.viewer,
      );
    });

    test('name falls back to email, then a placeholder', () {
      expect(const Member(uid: 'u', role: Role.viewer).name, 'Member');
      expect(
        const Member(uid: 'u', role: Role.viewer, email: 'a@b.co').name,
        'a@b.co',
      );
    });
  });

  group('CreateBusinessRequest', () {
    const request = CreateBusinessRequest(
      requestId: 'req12345',
      name: ' Shop ',
      currency: Currency.inr,
      timezone: 'Asia/Kolkata',
      template: BusinessTemplate.retail,
    );

    test('payload matches the callable contract', () {
      expect(request.toPayload(), {
        'requestId': 'req12345',
        'name': 'Shop',
        'currencyCode': 'INR',
        'timezone': 'Asia/Kolkata',
        'template': 'retail',
      });
    });

    test('sameInputAs ignores the request id', () {
      expect(request.sameInputAs(request.withRequestId('other123')), isTrue);
    });
  });

  group('TimeZones', () {
    test('labels known zones with their offset', () {
      expect(TimeZones.label('Asia/Kolkata'), 'Asia/Kolkata (UTC+05:30)');
      expect(
        TimeZones.label('America/New_York'),
        'America/New_York (UTC-05:00)',
      );
      expect(TimeZones.label('Mars/Base'), 'Mars/Base');
    });

    test('options always include the stored zone', () {
      expect(TimeZones.optionsIncluding('Europe/Paris').first, 'Europe/Paris');
      expect(
        TimeZones.optionsIncluding('Asia/Dubai'),
        TimeZones.names,
      );
    });

    test('device default is a name the picker can show', () {
      expect(TimeZones.deviceDefault(), isNotEmpty);
    });
  });

  test('every template seeds only known standard fields', () {
    for (final template in BusinessTemplate.values) {
      expect(template.standardFields, isNotEmpty);
      expect(BusinessTemplate.fromKey(template.key), template);
    }
  });
}
