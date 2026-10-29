import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement_rules.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transaction_fixtures.dart';

/// Keys `validDraft` in `firestore.rules` forbids on a client write.
const _forbidden = {
  'confirmedAt',
  'confirmedBy',
  'cancelledAt',
  'linkKind',
  'linkedTransactionId',
  'settlementId',
};

void main() {
  group('LedgerTransaction.fromMap', () {
    test('reads a confirmed document written by the functions', () {
      final tx = LedgerTransaction.fromMap('t1', const {
        'type': 'sale',
        'direction': 'in',
        'status': 'confirmed',
        'categoryId': 'c1',
        'categoryName': 'Sales',
        'partyName': 'Asha',
        'description': 'Cement',
        'date': '2026-10-01',
        'dueDate': '2026-10-10',
        'lineItems': [
          {
            'description': 'Bags',
            'quantityMilli': 2500,
            'rateMinor': 40000,
            'amountMinor': 100000,
          },
        ],
        'totalMinor': 100000,
        'paidMinor': 30000,
        'refundedMinor': 10000,
        'creditedMinor': 5000,
        'effectiveMinor': 85000,
        'outstandingMinor': 65000,
        'paymentStatus': 'partiallyRefunded',
        'isOpen': true,
        'customFields': {'f1': 'Site A'},
        'attachments': ['businesses/b1/attachments/t1/1_bill.pdf'],
        'version': 4,
        'createdBy': 'u1',
        'confirmedBy': 'u2',
      });
      expect(tx.type, TransactionType.sale);
      expect(tx.isConfirmed, isTrue);
      expect(tx.effectiveDirection, Direction.inflow);
      expect(tx.lineItems.single.amountMinor, 100000);
      expect(tx.lineItems.single.isConsistent, isTrue);
      expect(
        tx.balance,
        const Balance(
          total: 100000,
          paid: 30000,
          refunded: 10000,
          credited: 5000,
        ),
      );
      expect(tx.balance.outstanding, tx.outstandingMinor);
      expect(tx.paymentStatus, PaymentStatus.partiallyRefunded);
      expect(tx.version, 4);
      expect(tx.customFields, {'f1': 'Site A'});
      expect(tx.isOverdue(today), isTrue);
      expect(tx.isOverdue('2026-10-10'), isFalse);
      expect(tx.isRefundEntry, isFalse);
    });

    test('survives a malformed document instead of throwing', () {
      final tx = LedgerTransaction.fromMap('bad', const {
        'type': 42,
        'status': 'confirmed',
        'totalMinor': 12.5,
        'paidMinor': '100',
        'lineItems': ['nope', 7],
        'customFields': 'x',
        'attachments': [1, 'ok'],
        'paymentStatus': null,
      });
      expect(tx.type, TransactionType.expense);
      expect(tx.totalMinor, 0, reason: 'a fractional amount is not truncated');
      expect(tx.paidMinor, 0);
      expect(tx.lineItems, isEmpty);
      expect(tx.customFields, isEmpty);
      expect(tx.paymentStatus, isNull);
      expect(tx.title, 'Expense');
    });

    test('a refund entry is recognised by type or link', () {
      final entry = LedgerTransaction.fromMap('r1', const {
        'type': 'refund',
        'status': 'confirmed',
        'linkKind': 'refund',
        'linkedTransactionId': 't1',
      });
      expect(entry.isRefundEntry, isTrue);
      expect(entry.isSettleable, isFalse);
      expect(
        entry.settlementUnavailableReason(SettlementKind.payment),
        contains('original'),
      );
    });

    test('a draft is never overdue', () {
      final draft = draftExpense();
      expect(draft.isDraft, isTrue);
      expect(draft.isOverdue('2030-01-01'), isFalse);
    });
  });

  test('Settlement reads its balance snapshot', () {
    final settlement = Settlement.fromMap('req-1', const {
      'kind': 'refund',
      'amountMinor': 2000,
      'date': '2026-10-12',
      'method': 'UPI',
      'balanceAfter': {
        'totalMinor': 10000,
        'paidMinor': 8000,
        'refundedMinor': 2000,
        'creditedMinor': 0,
        'outstandingMinor': 2000,
        'paymentStatus': 'partiallyRefunded',
      },
      'linkedTransactionId': 'r1',
      'voided': false,
    });
    expect(settlement.kind, SettlementKind.refund);
    expect(settlement.balanceAfter?.refunded, 2000);
    expect(settlement.outstandingAfter, 2000);
    expect(settlement.paymentStatusAfter, PaymentStatus.partiallyRefunded);
    expect(settlement.linkedTransactionId, 'r1');
  });

  test('AuditEntry labels and changed keys', () {
    final entry = AuditEntry.fromMap('a1', const {
      'entity': 'transaction',
      'entityId': 't1',
      'action': 'edit',
      'before': {'totalMinor': 1, 'categoryName': 'A'},
      'after': {'totalMinor': 2, 'categoryName': 'B'},
    });
    expect(entry.label, 'Edited');
    expect(entry.changedKeys, ['totalMinor']);
  });

  group('LineItem', () {
    test('computes and rounds each line half away from zero', () {
      final line = LineItem.of(quantityMilli: 1500, rateMinor: 333);
      expect(line.amountMinor, 500); // 499.5 → 500
      expect(line.copyWith(quantityMilli: 1000).amountMinor, 333);
      expect(
        LineItem.total([line, LineItem.of(rateMinor: 100)]),
        600,
      );
    });
  });

  group('TransactionDraft.toMap', () {
    TransactionDraft draft() => TransactionDraft(
      id: 't9',
      type: TransactionType.sale,
      date: '2026-10-14',
      direction: Direction.inflow,
      categoryId: 'c1',
      categoryName: 'Sales',
      partyId: 'p1',
      partyName: 'Asha Traders',
      description: '  Cement bags  ',
      reference: 'PO-77',
      dueDate: '2026-10-30',
      useLineItems: true,
      lineItems: [
        LineItem.of(description: 'Bags', quantityMilli: 2000, rateMinor: 45000),
        LineItem.of(quantityMilli: 500, rateMinor: 999),
      ],
      totalMinor: 1,
      customFields: const {'f1': 'Site A', 'f2': '  ', 'f3': null, 'f4': false},
    );

    test('a new draft has exactly what validDraft accepts', () {
      const marker = 'server-time';
      final map = draft().toMap(uid: 'u1', isNew: true, now: marker);

      expect(map['status'], 'draft');
      expect(map['createdBy'], 'u1');
      expect(map['createdAt'], marker);
      expect(map['updatedAt'], marker);
      expect(map['version'], 0);
      expect(
        ['income', 'sale', 'expense', 'purchase', 'payment', 'adjustment'],
        contains(map['type']),
      );
      for (final key in ['paidMinor', 'refundedMinor', 'creditedMinor']) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
      expect(map.keys.toSet().intersection(_forbidden), isEmpty);
      for (final key in [
        'paymentStatus',
        'isOpen',
        'outstandingMinor',
        'effectiveMinor',
        // Text only: no attachments are written (validDraft allows absence).
        'attachments',
      ]) {
        expect(map.containsKey(key), isFalse, reason: key);
      }

      final total = map['totalMinor'];
      expect(total, isA<int>());
      expect(total, 90000 + 500); // lines win over the stale direct amount
      expect(total! as int, inInclusiveRange(0, 10000000000000));
      expect(map['description'], 'Cement bags');
      expect((map['description']! as String).length, lessThanOrEqualTo(200));
      expect(map['lineItems'], isA<List<Object?>>());
      expect((map['lineItems']! as List).length, lessThanOrEqualTo(200));
      expect(
        (map['lineItems']! as List).first,
        {
          'description': 'Bags',
          'quantityMilli': 2000,
          'rateMinor': 45000,
          'amountMinor': 90000,
        },
      );
      expect(map['customFields'], {'f1': 'Site A', 'f4': false});
      expect(map['direction'], 'in');
      expect(map['categoryName'], 'Sales');
      expect(
        map['searchTokens'],
        containsAll(<String>[
          'cem',
          'cement',
          'asha',
          'po',

          'sales',
        ]),
      );
    });

    test('an update leaves createdBy, createdAt and version alone', () {
      final map = draft().toMap(uid: 'u2', isNew: false, now: 'now');
      expect(map.containsKey('createdBy'), isFalse);
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('version'), isFalse);
      expect(map['status'], 'draft');
    });

    test('an unitemised draft writes its direct amount and no lines', () {
      const plain = TransactionDraft(
        id: 't1',
        type: TransactionType.payment,
        date: '2026-10-14',
        totalMinor: 2500,
      );
      final map = plain.toMap(uid: 'u1', isNew: true, now: 'now');
      expect(map['totalMinor'], 2500);
      expect(map['lineItems'], isEmpty);
      expect(map['direction'], isNull, reason: 'payment direction unchosen');
    });

    test('an empty amount is stored as 0, never null', () {
      const blank = TransactionDraft(
        id: 't1',
        type: TransactionType.expense,
        date: '2026-10-14',
      );
      expect(blank.toMap(uid: 'u', isNew: true, now: 0)['totalMinor'], 0);
    });

    test('toRow: a new draft is the whole row app.valid_draft accepts', () {
      final row = draft().toRow(uid: 'u1', businessId: 'b1', isNew: true);
      expect(row['id'], 't9');
      expect(row['business_id'], 'b1');
      expect(row['created_by'], 'u1');
      expect(row['version'], 0);
      expect(row['status'], 'draft');
      expect(row['total_minor'], 90500);
      expect(row['due_date'], '2026-10-30');
      expect(row['custom_fields'], {'f1': 'Site A', 'f4': false});
      expect((row['line_items']! as List).first, {
        'description': 'Bags',
        'quantityMilli': 2000,
        'rateMinor': 45000,
        'amountMinor': 90000,
      });
      // Nothing the server maintains, nothing camelCase at the top level.
      for (final key in [
        'paid_minor',
        'refunded_minor',
        'credited_minor',
        'effective_minor',
        'outstanding_minor',
        'payment_status',
        'is_open',
        'confirmed_at',
        'linked_transaction_id',
        'created_at',
        'updated_at',
        'seq',
      ]) {
        expect(row.containsKey(key), isFalse, reason: key);
      }
      expect(row.keys.where((key) => key.contains(RegExp('[A-Z]'))), isEmpty);
    });

    test('toRow: an update never touches id, business or creator', () {
      final row = draft().toRow(uid: 'u2', businessId: 'b1', isNew: false);
      for (final key in ['id', 'business_id', 'created_by', 'version']) {
        expect(row.containsKey(key), isFalse, reason: key);
      }
      expect(row['description'], 'Cement bags');
    });
  });

  group('LedgerTransaction.fromRow', () {
    test('reads a Postgres row (and its local pending mark)', () {
      final tx = LedgerTransaction.fromRow(const {
        'id': 't1',
        'business_id': 'b1',
        'type': 'sale',
        'direction': 'in',
        'status': 'confirmed',
        'category_id': 'c1',
        'party_name': 'Asha',
        'date': '2026-10-01',
        'due_date': '2026-10-10',
        'line_items': [
          {
            'description': 'Bags',
            'quantityMilli': 2500,
            'rateMinor': 40000,
            'amountMinor': 100000,
          },
        ],
        'total_minor': 100000,
        'paid_minor': 30000,
        'outstanding_minor': 70000,
        'payment_status': 'partiallyPaid',
        'is_open': true,
        'custom_fields': {'f1': 'x'},
        'search_tokens': ['ash', 'asha'],
        'version': 3,
        'created_by': 'u1',
        'created_at': '2026-10-01T05:00:00+00:00',
        'local_pending': true,
      });
      expect(tx.id, 't1');
      expect(tx.categoryId, 'c1');
      expect(tx.dueDate, '2026-10-10');
      expect(tx.lineItems.single.amountMinor, 100000);
      expect(tx.outstandingMinor, 70000);
      expect(tx.paymentStatus, PaymentStatus.partiallyPaid);
      expect(tx.isOpen, isTrue);
      expect(tx.customFields, {'f1': 'x'});
      expect(tx.searchTokens, ['ash', 'asha']);
      expect(tx.version, 3);
      expect(tx.createdAt, DateTime.utc(2026, 10, 1, 5).toLocal());
      expect(tx.hasPendingWrites, isTrue);
    });

    test('JSON columns stored as text read the same', () {
      final tx = LedgerTransaction.fromRow(const {
        'id': 't1',
        'type': 'expense',
        'status': 'draft',
        'line_items':
            '[{"description":"x","quantityMilli":1000,'
            '"rateMinor":5,"amountMinor":5}]',
        'custom_fields': '{"f1":"y"}',
        'search_tokens': '["x"]',
      });
      expect(tx.lineItems.single.amountMinor, 5);
      expect(tx.customFields, {'f1': 'y'});
      expect(tx.searchTokens, ['x']);
      expect(tx.hasPendingWrites, isFalse);
    });
  });

  group('TransactionDraft.changesFrom', () {
    test('sends only the keys that changed', () {
      final original = confirmedSale();
      final draft = TransactionDraft.fromTransaction(
        original,
        fallbackDate: today,
      );
      expect(draft.changesFrom(original), isEmpty);

      final edited = draft.copyWith(
        description: 'Cement bags (50)',
        dueDate: () => '2026-11-01',
        partyId: () => null,
        totalMinor: () => 120000,
      );
      expect(edited.changesFrom(original), {
        'description': 'Cement bags (50)',
        'dueDate': '2026-11-01',
        'partyId': null,
        'totalMinor': 120000,
      });
    });

    test('switching lines off sends an empty list and the total', () {
      final original = confirmedSale();
      final itemised = LedgerTransaction.fromMap('t1', const {
        'type': 'sale',
        'status': 'confirmed',
        'date': '2026-10-01',
        'categoryId': 'c1',
        'totalMinor': 1000,
        'lineItems': [
          {
            'description': '',
            'quantityMilli': 1000,
            'rateMinor': 1000,
            'amountMinor': 1000,
          },
        ],
      });
      final draft = TransactionDraft.fromTransaction(
        itemised,
        fallbackDate: today,
      ).copyWith(useLineItems: false, totalMinor: () => 1000);
      expect(draft.changesFrom(itemised), {'lineItems': <Object>[]});
      expect(original.totalMinor, 100000);
    });
  });

  test('the receipt date travels in the row and in edits', () {
    final original = confirmedSale();
    final draft = TransactionDraft.fromTransaction(
      original,
      fallbackDate: today,
    ).copyWith(receiptDate: () => '2024-03-15');
    expect(
      draft.toRow(uid: 'u1', businessId: 'b1', isNew: false)['receipt_date'],
      '2024-03-15',
    );
    expect(draft.changesFrom(original), {'receiptDate': '2024-03-15'});
    final stored = LedgerTransaction.fromRow(const {
      'id': 't9',
      'type': 'expense',
      'status': 'draft',
      'date': '2026-10-27',
      'receipt_date': '2024-03-15',
    });
    expect(stored.receiptDate, '2024-03-15');
    expect(stored.date, '2026-10-27');
    // A copy is a new entry, not the same receipt.
    expect(draft.duplicateAs(id: 'n1', date: today).receiptDate, isNull);
  });

  test('duplicateAs makes a fresh draft and drops a past due date', () {
    final source = TransactionDraft.fromTransaction(
      confirmedSale(dueDate: '2026-10-10'),
      fallbackDate: today,
    );
    final copy = source.duplicateAs(id: 'n1', date: today);
    expect(copy.id, 'n1');
    expect(copy.date, today);
    expect(copy.dueDate, isNull);
    expect(copy.total, source.total);
  });

  group('TransactionFilter', () {
    final paid = confirmedSale(
      id: 'paid',
      paid: 100000,
      status: PaymentStatus.paid,
    );
    final overdue = confirmedSale(id: 'late', dueDate: '2026-10-05');
    final draft = draftExpense();

    test('stored and derived payment filters', () {
      final items = [paid, overdue, draft];
      List<String> ids(TransactionFilter filter) => [
        for (final tx in filter.apply(items, today)) tx.id,
      ];
      expect(ids(const TransactionFilter(payment: PaymentFilter.paid)), [
        'paid',
      ]);
      expect(ids(const TransactionFilter(payment: PaymentFilter.overdue)), [
        'late',
      ]);
      expect(ids(TransactionFilter.outstanding), ['late']);
      expect(
        ids(const TransactionFilter(status: TransactionStatus.draft)),
        ['d1'],
      );
    });

    test('search needs every word as a stored prefix', () {
      expect(
        const TransactionFilter(search: 'asha cem').matches(paid, today),
        isTrue,
      );
      expect(
        const TransactionFilter(search: 'asha steel').matches(paid, today),
        isFalse,
      );
    });

    test('date range and amount sort', () {
      final small = confirmedSale(id: 's', total: 10);
      final big = confirmedSale(id: 'b', total: 999999);
      final sorted = const TransactionFilter(
        sort: TransactionSort.amountDesc,
      ).apply([small, big, paid], today);
      expect(sorted.map((t) => t.id), ['b', 'paid', 's']);
      expect(
        const TransactionFilter(from: '2026-10-02').matches(paid, today),
        isFalse,
      );
      expect(
        const TransactionFilter(
          from: '2026-10-01',
          to: '2026-10-01',
        ).matches(paid, today),
        isTrue,
      );
    });
  });

  group('settlement rules (LedgerMath on a transaction)', () {
    test('kinds unavailable with the reason', () {
      final unpaid = confirmedSale();
      expect(unpaid.canSettle(SettlementKind.payment), isTrue);
      expect(
        unpaid.settlementUnavailableReason(SettlementKind.refund),
        contains('nothing to refund'),
      );
      final settled = confirmedSale(paid: 100000, status: PaymentStatus.paid);
      expect(settled.canSettle(SettlementKind.payment), isFalse);
      expect(settled.maxSettlement(SettlementKind.refund), 100000);
      expect(
        draftExpense().settlementUnavailableReason(SettlementKind.payment),
        'Confirm the transaction first.',
      );
    });

    test('preview and payment status after', () {
      final tx = confirmedSale(
        paid: 40000,
        status: PaymentStatus.partiallyPaid,
      );
      final next = tx.previewSettlement(SettlementKind.payment, 60000);
      expect(next.outstanding, 0);
      expect(tx.paymentStatusFor(next), PaymentStatus.paid);
    });

    test('cancel needs net paid at zero', () {
      expect(
        confirmedSale(paid: 1).cancelBlockedReason(),
        LedgerViolation.cancelWithMoney.message,
      );
      expect(confirmedSale().cancelBlockedReason(), isNull);
      expect(
        confirmedSale(paid: 500, refunded: 500).cancelBlockedReason(),
        isNull,
      );
    });
  });

  group('LedgerDates', () {
    test('validates real calendar days', () {
      expect(LedgerDates.isValid('2026-02-28'), isTrue);
      expect(LedgerDates.isValid('2026-02-30'), isFalse);
      expect(LedgerDates.isValid('2026-2-3'), isFalse);
      expect(LedgerDates.today(now), today);
      expect(LedgerDates.sectionLabel('2026-10-13', today), 'Yesterday');
    });
  });
}
