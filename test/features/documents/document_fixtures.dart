import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A document map as `issueDocument` writes it (an invoice, INR, two lines,
/// partly paid with a credit).
Map<String, dynamic> invoiceMap({
  bool voided = false,
  String symbol = '₹',
  Map<String, dynamic>? party = const {
    'name': 'Asha Traders',
    'address': '12 MG Road, Bengaluru',
    'phone': '+91 98450 00000',
    'email': 'accounts@asha.example',
  },
}) => {
  'type': 'invoice',
  'number': 'INV-2026-0007',
  'transactionId': 'tx1',
  'settlementId': null,
  'snapshot': {
    'business': {
      'name': 'Kumar & Co',
      'address': '1 Residency Road',
      'phone': '080 1234 5678',
      'email': 'hello@kumar.example',
      'taxId': '29ABCDE1234F1Z5',
      'currency': {'code': 'INR', 'decimals': 2, 'symbol': symbol},
    },
    'party': party,
    'transaction': {
      'type': 'sale',
      'direction': 'in',
      'description': 'Website build',
      'reference': 'PO-88',
      'date': '2026-10-01',
      'dueDate': '2026-10-15',
      'categoryName': 'Services',
      'projectName': null,
      'paymentMethod': '',
      'notes': 'Bank: HDFC 0001',
      'lineItems': [
        {
          'description': 'Design',
          'quantityMilli': 2500,
          'rateMinor': 400000,
          'amountMinor': 1000000,
        },
        {
          'description': 'Hosting',
          'quantityMilli': 1000,
          'rateMinor': 250050,
          'amountMinor': 250050,
        },
      ],
      'totalMinor': 1250050,
      'creditedMinor': 50000,
      'paidMinor': 600000,
      'refundedMinor': 0,
      'outstandingMinor': 600050,
      'paymentStatus': 'partiallyPaid',
    },
    'settlement': null,
  },
  'issuedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 2, 9)),
  'issuedBy': 'u1',
  'voided': voided,
  'storagePath': null,
};

/// A purchase bill with no line items and no party.
Map<String, dynamic> billMap() {
  final map = invoiceMap(party: null);
  final snapshot = map['snapshot'] as Map<String, dynamic>;
  map
    ..['type'] = 'bill'
    ..['number'] = 'BILL-2026-0003';
  snapshot['transaction'] = {
    'type': 'purchase',
    'direction': 'out',
    'description': 'Printer paper',
    'date': '2026-10-03',
    'lineItems': <Object>[],
    'totalMinor': 45000,
    'paymentStatus': 'unpaid',
    'outstandingMinor': 45000,
  };
  return map;
}

/// A receipt for the second instalment of the invoice.
Map<String, dynamic> receiptMap() {
  final map = invoiceMap()
    ..['type'] = 'receipt'
    ..['number'] = 'RCPT-2026-0011'
    ..['settlementId'] = 'req123456';
  (map['snapshot'] as Map<String, dynamic>)['settlement'] = {
    'amountMinor': 200000,
    'date': '2026-10-10',
    'method': 'UPI',
    'note': 'Second instalment',
    'paidToDateMinor': 600000,
    'remainingMinor': 600050,
  };
  return map;
}

IssuedDocument invoice({bool voided = false, String symbol = '₹'}) =>
    IssuedDocument.fromMap(
      'invoice-tx1-main',
      invoiceMap(voided: voided, symbol: symbol),
    );

IssuedDocument bill() => IssuedDocument.fromMap('bill-tx2-main', billMap());

IssuedDocument receipt() =>
    IssuedDocument.fromMap('receipt-tx1-req123456', receiptMap());
