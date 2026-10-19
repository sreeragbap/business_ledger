import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:flutter_test/flutter_test.dart';

import 'document_fixtures.dart';

void main() {
  group('IssuedDocument.fromMap', () {
    test('parses an invoice snapshot with integer minor units', () {
      final doc = invoice();
      expect(doc.type, DocumentType.invoice);
      expect(doc.number, 'INV-2026-0007');
      expect(doc.settlementId, isNull);
      expect(
        doc.issuedAt!.isAtSameMomentAs(DateTime.utc(2026, 10, 2, 9)),
        isTrue,
      );
      expect(doc.voided, isFalse);
      expect(doc.fileName, 'INV-2026-0007.pdf');

      final snapshot = doc.snapshot;
      expect(snapshot.currency, Currency.inr);
      expect(snapshot.business.taxId, '29ABCDE1234F1Z5');
      expect(snapshot.party!.name, 'Asha Traders');

      final tx = snapshot.transaction;
      expect(tx.type, TransactionType.sale);
      expect(tx.direction, Direction.inflow);
      expect(tx.dueDate, '2026-10-15');
      expect(tx.lineItems, hasLength(2));
      expect(tx.lineItems.first.quantityMilli, 2500);
      expect(tx.totalMinor, 1250050);
      expect(tx.creditedMinor, 50000);
      expect(tx.paymentStatus, PaymentStatus.partiallyPaid);
      expect(snapshot.settlement, isNull);
    });

    test('defaults missing optional amounts and texts', () {
      final tx = bill().snapshot.transaction;
      expect(tx.paidMinor, 0);
      expect(tx.refundedMinor, 0);
      expect(tx.creditedMinor, 0);
      expect(tx.reference, '');
      expect(tx.lineItems, isEmpty);
      expect(bill().snapshot.party, isNull);
    });

    test('parses a receipt settlement', () {
      final settlement = receipt().snapshot.settlement!;
      expect(settlement.amountMinor, 200000);
      expect(settlement.method, 'UPI');
      expect(settlement.paidToDateMinor, 600000);
      expect(settlement.remainingMinor, 600050);
    });

    test('accepts a whole double but rejects a fractional amount', () {
      final whole = invoiceMap();
      ((whole['snapshot'] as Map)['transaction'] as Map)['totalMinor'] =
          1250050.0;
      expect(
        IssuedDocument.fromMap('x', whole).snapshot.transaction.totalMinor,
        1250050,
      );

      final fractional = invoiceMap();
      ((fractional['snapshot'] as Map)['transaction'] as Map)['totalMinor'] =
          12500.5;
      expect(
        () => IssuedDocument.fromMap('x', fractional),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('totalMinor'),
          ),
        ),
      );
    });

    test('rejects unknown enums and missing required fields', () {
      final badType = invoiceMap()..['type'] = 'quote';
      expect(
        () => IssuedDocument.fromMap('x', badType),
        throwsFormatException,
      );

      final noBusiness = invoiceMap();
      (noBusiness['snapshot'] as Map).remove('business');
      expect(
        () => IssuedDocument.fromMap('x', noBusiness),
        throwsFormatException,
      );

      final badDate = invoiceMap();
      ((badDate['snapshot'] as Map)['transaction'] as Map)['date'] = '1/10/26';
      expect(() => IssuedDocument.fromMap('x', badDate), throwsFormatException);
    });

    test('a pending server timestamp parses as null', () {
      final map = invoiceMap()..['issuedAt'] = null;
      expect(IssuedDocument.fromMap('x', map).issuedAt, isNull);
    });

    test('idFor matches the server scheme', () {
      expect(
        IssuedDocument.idFor(type: DocumentType.invoice, transactionId: 't'),
        'invoice-t-main',
      );
      expect(
        IssuedDocument.idFor(
          type: DocumentType.receipt,
          transactionId: 't',
          settlementId: 's',
        ),
        'receipt-t-s',
      );
    });
  });

  test('IssueResult parses the callable result strictly', () {
    expect(
      IssueResult.fromMap(const {
        'documentId': 'invoice-tx1-main',
        'number': 'INV-2026-0001',
        'created': true,
      }),
      const IssueResult(
        documentId: 'invoice-tx1-main',
        number: 'INV-2026-0001',
        created: true,
      ),
    );
    expect(
      () => IssueResult.fromMap(const {'number': 'x'}),
      throwsFormatException,
    );
  });
}
