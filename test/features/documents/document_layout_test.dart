import 'dart:convert';

import 'package:business_ledger/features/documents/domain/models/document_layout_data.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:business_ledger/features/documents/domain/pdf/document_fonts.dart';
import 'package:business_ledger/features/documents/domain/pdf/document_pdf_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'document_fixtures.dart';

void main() {
  group('DocumentLayoutData', () {
    test('invoice: lines, totals and balance from integer minor units', () {
      final layout = DocumentLayoutData.from(invoice());

      expect(layout.title, 'INVOICE');
      expect(layout.number, 'INV-2026-0007');
      expect(layout.businessLines, [
        '1 Residency Road',
        '080 1234 5678',
        'hello@kumar.example',
        'Tax ID: 29ABCDE1234F1Z5',
      ]);
      expect(layout.partyHeading, 'Bill to');
      expect(layout.partyLines.first, 'Asha Traders');
      expect(layout.details, [
        const LayoutRow('Invoice no.', 'INV-2026-0007'),
        const LayoutRow('Issue date', '2 Oct 2026'),
        const LayoutRow('Date', '1 Oct 2026'),
        const LayoutRow('Due date', '15 Oct 2026'),
        const LayoutRow('Reference', 'PO-88'),
      ]);
      expect(layout.lines, [
        const LayoutLine(
          description: 'Design',
          quantity: '2.5',
          rate: '₹4,000.00',
          amount: '₹10,000.00',
        ),
        const LayoutLine(
          description: 'Hosting',
          quantity: '1',
          rate: '₹2,500.50',
          amount: '₹2,500.50',
        ),
      ]);
      expect(layout.totals, [
        const LayoutRow('Subtotal', '₹12,500.50'),
        const LayoutRow('Credits / discounts', '-₹500.00'),
        const LayoutRow('Total', '₹12,000.50'),
        const LayoutRow('Paid', '₹6,000.00'),
        const LayoutRow('Balance due', '₹6,000.50', emphasis: true),
      ]);
      expect(layout.receipt, isEmpty);
      expect(layout.notes, 'Bank: HDFC 0001');
      expect(layout.voided, isFalse);
    });

    test('falls back to the currency code when the font lacks the symbol', () {
      final fonts = DocumentFonts.builtIn();
      final layout = DocumentLayoutData.from(
        invoice(),
        canRender: fonts.canRender,
      );
      expect(layout.totals.last.value, 'INR 6,000.50');
      expect(layout.lines.first.rate, 'INR 4,000.00');

      // £ is Latin-1, so Helvetica keeps it.
      final pounds = DocumentLayoutData.from(
        invoice(symbol: '£'),
        canRender: fonts.canRender,
      );
      expect(pounds.totals.last.value, '£6,000.50');
    });

    test('bill without line items or party shows one line and From', () {
      final layout = DocumentLayoutData.from(bill());
      expect(layout.title, 'BILL');
      expect(layout.partyHeading, 'From');
      expect(layout.partyLines, isEmpty);
      expect(layout.lines, [
        const LayoutLine(
          description: 'Printer paper',
          quantity: '1',
          rate: '₹450.00',
          amount: '₹450.00',
        ),
      ]);
      expect(layout.totals.map((row) => row.label), [
        'Subtotal',
        'Total',
        'Paid to supplier',
        'Balance due',
      ]);
    });

    test('receipt (partial payment): amount, paid to date, remaining', () {
      final layout = DocumentLayoutData.from(receipt());
      expect(layout.title, 'RECEIPT');
      expect(layout.partyHeading, 'Received from');
      expect(layout.isReceipt, isTrue);
      expect(layout.receipt, [
        const LayoutRow('Amount received', '₹2,000.00', emphasis: true),
        const LayoutRow('Payment date', '10 Oct 2026'),
        const LayoutRow('Method', 'UPI'),
        const LayoutRow('Paid to date', '₹6,000.00'),
        const LayoutRow('Remaining balance', '₹6,000.50'),
      ]);
      // A receipt does not repeat the invoice's balance-due block.
      expect(layout.totals.map((r) => r.label), isNot(contains('Balance due')));
      expect(layout.notes, contains('Second instalment'));
      expect(
        layout.details.map((r) => r.label),
        isNot(contains('Due date')),
      );
    });

    test('voided documents are flagged', () {
      expect(DocumentLayoutData.from(invoice(voided: true)).voided, isTrue);
    });
  });

  group('DocumentFonts.builtIn', () {
    test('sanitises characters Helvetica cannot draw', () {
      final fonts = DocumentFonts.builtIn();
      expect(fonts.canRender('Café £5'), isTrue);
      expect(fonts.canRender('₹5'), isFalse);
      expect(fonts.sanitise('A — B ₹ 東'), 'A - B INR  ?');
    });
  });

  group('DocumentPdfBuilder', () {
    // Uncompressed so the drawn content can be inspected.
    const builder = DocumentPdfBuilder(compress: false);

    Future<String> render(DocumentLayoutData data) async {
      final bytes = await builder.build(data, fonts: DocumentFonts.builtIn());
      expect(bytes.length, greaterThan(1000));
      final head = latin1.decode(bytes.sublist(0, 8));
      expect(head, startsWith('%PDF-'));
      return latin1.decode(bytes);
    }

    final fonts = DocumentFonts.builtIn();
    DocumentLayoutData layoutOf(IssuedDocument doc) =>
        DocumentLayoutData.from(doc, canRender: fonts.canRender);

    test('renders an invoice on one page', () async {
      expect(_pages(await render(layoutOf(invoice()))), 1);
    });

    test('renders a bill', () async {
      await render(layoutOf(bill()));
    });

    test('renders a receipt for a partial payment', () async {
      await render(layoutOf(receipt()));
    });

    test('renders a voided document', () async {
      final voided = await render(layoutOf(invoice(voided: true)));
      final normal = await render(layoutOf(invoice()));
      expect(voided, contains('VOID'));
      expect(normal, isNot(contains('VOID')));
    });

    test(
      'buildDocument survives a non-Latin party name with Helvetica',
      () async {
        final map = invoiceMap(party: {'name': 'आशा ट्रेडर्स'});
        final doc = IssuedDocument.fromMap('x', map);
        final bytes = await builder.buildDocument(doc, fonts: fonts);
        expect(bytes, isNotEmpty);
      },
    );

    test('long documents paginate', () async {
      final base = layoutOf(invoice());
      final long = DocumentLayoutData(
        title: base.title,
        number: base.number,
        businessName: base.businessName,
        businessLines: base.businessLines,
        partyHeading: base.partyHeading,
        partyLines: base.partyLines,
        details: base.details,
        lines: List.filled(120, base.lines.first),
        totals: base.totals,
        receipt: base.receipt,
        notes: base.notes,
        voided: false,
        footer: base.footer,
      );
      final text = await render(long);
      expect(_pages(text), greaterThan(1));
    });
  });
}

int _pages(String pdf) => RegExp(r'/Type\s*/Page\b').allMatches(pdf).length;
