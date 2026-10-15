import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/documents/domain/models/document_action.dart';
import 'package:business_ledger/features/documents/widgets/document_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';
import 'document_fixtures.dart';

DocumentSubject _subject({
  TransactionType type = TransactionType.sale,
  TransactionStatus status = TransactionStatus.confirmed,
  List<DocumentPaymentRef> payments = const [],
}) => DocumentSubject(
  businessId: 'b1',
  transactionId: 'tx1',
  type: type,
  status: status,
  currency: Currency.inr,
  payments: payments,
);

const _payment = DocumentPaymentRef(
  settlementId: 'req123456',
  kind: SettlementKind.payment,
  amountMinor: 200000,
  date: '2026-10-10',
);

void main() {
  group('DocumentActions.forSubject', () {
    test('a confirmed sale offers an invoice and a receipt per payment', () {
      final actions = DocumentActions.forSubject(
        _subject(
          payments: [
            _payment,
            const DocumentPaymentRef(
              settlementId: 'credit1',
              kind: SettlementKind.credit,
              amountMinor: 100,
              date: '2026-10-11',
            ),
            const DocumentPaymentRef(
              settlementId: 'void1',
              kind: SettlementKind.payment,
              amountMinor: 100,
              date: '2026-10-11',
              voided: true,
            ),
          ],
        ),
        issued: const [],
        online: true,
      );
      expect(actions.map((a) => (a.type, a.settlementId, a.enabled)), [
        (DocumentType.invoice, null, true),
        (DocumentType.receipt, 'req123456', true),
      ]);
      expect(actions.first.title, 'Issue invoice');
      expect(actions.last.title, 'Issue receipt for ₹2,000.00');
      expect(actions.last.subtitle, 'Payment on 10 Oct 2026');
    });

    test('a purchase offers a bill', () {
      final actions = DocumentActions.forSubject(
        _subject(type: TransactionType.purchase),
        issued: const [],
        online: true,
      );
      expect(actions.single.type, DocumentType.bill);
    });

    test('drafts and cancelled entries are disabled with a reason', () {
      final draft = DocumentActions.forSubject(
        _subject(status: TransactionStatus.draft),
        issued: const [],
        online: true,
      ).single;
      expect(draft.enabled, isFalse);
      expect(draft.disabledReason, DocumentActions.draftReason);

      final cancelled = DocumentActions.forSubject(
        _subject(status: TransactionStatus.cancelled),
        issued: const [],
        online: true,
      ).single;
      expect(cancelled.disabledReason, DocumentActions.cancelledReason);
    });

    test('issuing is disabled offline, opening an issued one is not', () {
      final offline = DocumentActions.forSubject(
        _subject(payments: [_payment]),
        issued: [invoice()],
        online: false,
      );
      expect(offline.first.isIssued, isTrue);
      expect(offline.first.enabled, isTrue);
      expect(offline.first.title, 'View invoice');
      expect(offline.first.subtitle, 'INV-2026-0007 · Issued');
      expect(offline.last.disabledReason, DocumentActions.offlineReason);
    });

    test('a cancelled transaction can still open its voided invoice', () {
      final action = DocumentActions.forSubject(
        _subject(status: TransactionStatus.cancelled),
        issued: [invoice(voided: true)],
        online: true,
      ).single;
      expect(action.enabled, isTrue);
      expect(action.subtitle, 'INV-2026-0007 · Void');
    });

    test('an adjustment without payments has nothing to offer', () {
      final subject = _subject(type: TransactionType.adjustment);
      expect(
        DocumentActions.forSubject(subject, issued: const [], online: true),
        isEmpty,
      );
      expect(
        DocumentActions.emptyMessage(subject),
        contains("doesn't have an invoice"),
      );
    });
  });

  testWidgets('DocumentActionsSheet lists actions and reports taps', (
    tester,
  ) async {
    DocumentAction? picked;
    await tester.pumpApp(
      DocumentActionsSheet(
        subject: _subject(payments: [_payment]),
        issued: const [],
        online: true,
        onSelected: (action) => picked = action,
      ),
    );
    expect(find.text('Issue invoice'), findsOneWidget);
    expect(find.text('Issue receipt for ₹2,000.00'), findsOneWidget);

    await tester.tap(find.text('Issue invoice'));
    expect(picked?.type, DocumentType.invoice);
  });

  testWidgets('DocumentActionsSheet shows why an action is disabled', (
    tester,
  ) async {
    DocumentAction? picked;
    await tester.pumpApp(
      DocumentActionsSheet(
        subject: _subject(status: TransactionStatus.draft),
        issued: const [],
        online: true,
        onSelected: (action) => picked = action,
      ),
    );
    expect(find.text(DocumentActions.draftReason), findsOneWidget);
    await tester.tap(find.text('Issue invoice'));
    expect(picked, isNull);
    expect(tester.takeException(), isNull);
    expect(find.byType(Semantics), findsWidgets);
  });
}
