import 'package:business_ledger/core/firebase/firestore_read.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// `transactions/{tid}/settlements/{requestId}`: one payment, refund or
/// credit, written only by `recordSettlement` (or `confirmTransaction` with
/// `settleNow`). The id is the request id, so a retry cannot duplicate it.
class Settlement extends Equatable {
  const Settlement({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.date,
    this.dateTs,
    this.method = '',
    this.note = '',
    this.balanceAfter,
    this.outstandingAfter,
    this.paymentStatusAfter,
    this.linkedTransactionId,
    this.createdBy = '',
    this.createdAt,
    this.voided = false,
  });

  factory Settlement.fromFirestore(DocumentSnapshot<JsonMap> doc) =>
      Settlement.fromMap(doc.id, doc.data() ?? const {});

  factory Settlement.fromMap(String id, Map<String, dynamic> map) {
    final after = map.readMap('balanceAfter');
    final status = after.readOptionalString('paymentStatus');
    return Settlement(
      id: id,
      kind: SettlementKind.fromKey(map.readOptionalString('kind')),
      amountMinor: map.readInt('amountMinor'),
      date: map.readString('date'),
      dateTs: map.readDate('dateTs'),
      method: map.readString('method'),
      note: map.readString('note'),
      balanceAfter: after.isEmpty
          ? null
          : Balance(
              total: after.readInt('totalMinor'),
              paid: after.readInt('paidMinor'),
              refunded: after.readInt('refundedMinor'),
              credited: after.readInt('creditedMinor'),
            ),
      outstandingAfter: after.readOptionalInt('outstandingMinor'),
      paymentStatusAfter: status == null ? null : PaymentStatus.fromKey(status),
      linkedTransactionId: map.readOptionalString('linkedTransactionId'),
      createdBy: map.readString('createdBy'),
      createdAt: map.readDate('createdAt'),
      voided: map.readBool('voided'),
    );
  }

  final String id;
  final SettlementKind kind;
  final int amountMinor;

  /// `yyyy-MM-dd`: when the money moved, not the transaction date.
  final String date;
  final DateTime? dateTs;
  final String method;
  final String note;

  /// The transaction's balance right after this settlement.
  final Balance? balanceAfter;
  final int? outstandingAfter;
  final PaymentStatus? paymentStatusAfter;

  /// For a refund: the visible refund entry it created.
  final String? linkedTransactionId;
  final String createdBy;
  final DateTime? createdAt;
  final bool voided;

  @override
  List<Object?> get props => [
    id,
    kind,
    amountMinor,
    date,
    dateTs,
    method,
    note,
    balanceAfter,
    outstandingAfter,
    paymentStatusAfter,
    linkedTransactionId,
    createdBy,
    createdAt,
    voided,
  ];
}
