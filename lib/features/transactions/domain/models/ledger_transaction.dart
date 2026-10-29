import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:equatable/equatable.dart';

/// A `transactions` row (ARCHITECTURE §4).
///
/// Named `LedgerTransaction` so it never collides with drift's and the
/// database's transactions. Drafts are written by the client (see
/// `TransactionDraft`); every other field — the money figures,
/// `paymentStatus`, `isOpen`, the name snapshots, `version` — is maintained
/// by the server's RPCs.
///
/// Parsing is strict about meaning and safe about shape (`JsonRead`): a
/// missing or malformed field falls back instead of throwing, so one bad
/// row can never break a list.
class LedgerTransaction extends Equatable {
  const LedgerTransaction({
    required this.id,
    required this.type,
    required this.status,
    this.direction,
    this.categoryId,
    this.categoryName,
    this.partyId,
    this.partyName,
    this.projectId,
    this.projectName,
    this.description = '',
    this.reference = '',
    this.notes = '',
    this.paymentMethod = '',
    this.date,
    this.dueDate,
    this.receiptDate,
    this.lineItems = const [],
    this.totalMinor = 0,
    this.paidMinor = 0,
    this.refundedMinor = 0,
    this.creditedMinor = 0,
    this.effectiveMinor = 0,
    this.outstandingMinor = 0,
    this.paymentStatus,
    this.isOpen = false,
    this.customFields = const {},
    this.searchTokens = const [],
    this.linkedTransactionId,
    this.linkKind,
    this.settlementId,
    this.version = 0,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.confirmedAt,
    this.confirmedBy,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason = '',
    this.hasPendingWrites = false,
  });

  /// A Postgres row (snake_case), from the server or the local store.
  /// `local_pending` (local only) becomes [hasPendingWrites].
  factory LedgerTransaction.fromRow(Map<String, dynamic> row) =>
      LedgerTransaction.fromMap(
        row.readString('id'),
        RowKeys.camelMap(row),
        hasPendingWrites: row['local_pending'] == true,
      );

  factory LedgerTransaction.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool hasPendingWrites = false,
  }) {
    final direction = map.readOptionalString('direction');
    final paymentStatus = map.readOptionalString('paymentStatus');
    final lines = map.readList('lineItems');
    return LedgerTransaction(
      id: id,
      type: TransactionType.fromKey(map.readOptionalString('type')),
      status: TransactionStatus.fromKey(map.readOptionalString('status')),
      direction: direction == null ? null : Direction.fromKey(direction),
      categoryId: map.readOptionalString('categoryId'),
      categoryName: map.readOptionalString('categoryName'),
      partyId: map.readOptionalString('partyId'),
      partyName: map.readOptionalString('partyName'),
      projectId: map.readOptionalString('projectId'),
      projectName: map.readOptionalString('projectName'),
      description: map.readString('description'),
      reference: map.readString('reference'),
      notes: map.readString('notes'),
      paymentMethod: map.readString('paymentMethod'),
      date: map.readOptionalString('date'),
      dueDate: map.readOptionalString('dueDate'),
      receiptDate: map.readOptionalString('receiptDate'),
      lineItems: lines.isNotEmpty
          ? List.unmodifiable([
              for (final line in lines)
                if (line is Map)
                  LineItem.fromMap(
                    line.map((key, value) => MapEntry('$key', value)),
                  ),
            ])
          : const [],
      totalMinor: map.readInt('totalMinor'),
      paidMinor: map.readInt('paidMinor'),
      refundedMinor: map.readInt('refundedMinor'),
      creditedMinor: map.readInt('creditedMinor'),
      effectiveMinor: map.readInt('effectiveMinor'),
      outstandingMinor: map.readInt('outstandingMinor'),
      paymentStatus: paymentStatus == null
          ? null
          : PaymentStatus.fromKey(paymentStatus),
      isOpen: map.readBool('isOpen'),
      customFields: Map.unmodifiable(map.readMap('customFields')),
      searchTokens: map.readStringList('searchTokens'),
      linkedTransactionId: map.readOptionalString('linkedTransactionId'),
      linkKind: map.readOptionalString('linkKind'),
      settlementId: map.readOptionalString('settlementId'),
      version: map.readInt('version'),
      createdBy: map.readString('createdBy'),
      createdAt: map.readDate('createdAt'),
      updatedAt: map.readDate('updatedAt'),
      updatedBy: map.readOptionalString('updatedBy'),
      confirmedAt: map.readDate('confirmedAt'),
      confirmedBy: map.readOptionalString('confirmedBy'),
      cancelledAt: map.readDate('cancelledAt'),
      cancelledBy: map.readOptionalString('cancelledBy'),
      cancelReason: map.readString('cancelReason'),
      hasPendingWrites: hasPendingWrites,
    );
  }

  final String id;
  final TransactionType type;
  final TransactionStatus status;

  /// `null` on a payment/adjustment draft whose direction is not chosen yet.
  final Direction? direction;
  final String? categoryId;

  /// Name snapshots, refreshed by the server on confirm and edit.
  final String? categoryName;
  final String? partyId;
  final String? partyName;
  final String? projectId;
  final String? projectName;
  final String description;
  final String reference;
  final String notes;
  final String paymentMethod;

  /// `yyyy-MM-dd`.
  final String? date;
  final String? dueDate;

  /// The date printed on the receipt or bill, beside [date] (the day the
  /// entry was made).
  final String? receiptDate;
  final List<LineItem> lineItems;

  final int totalMinor;
  final int paidMinor;
  final int refundedMinor;
  final int creditedMinor;
  final int effectiveMinor;
  final int outstandingMinor;

  /// `null` on drafts (never written by the client).
  final PaymentStatus? paymentStatus;
  final bool isOpen;

  /// `{fieldId: value}`; see `FieldType` for each value's shape.
  final Map<String, dynamic> customFields;

  final List<String> searchTokens;

  /// On a refund entry: the original transaction.
  final String? linkedTransactionId;
  final String? linkKind;

  /// On a refund entry: the settlement on the original that created it.
  final String? settlementId;

  /// Bumped on every server write; sent back as `expectedVersion`.
  final int version;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String cancelReason;

  /// Changed on this device and not uploaded yet (`local_pending`: an
  /// offline draft). Not a server column.
  final bool hasPendingWrites;

  bool get isDraft => status == TransactionStatus.draft;
  bool get isConfirmed => status == TransactionStatus.confirmed;
  bool get isCancelled => status == TransactionStatus.cancelled;

  /// The visible ledger entry the server creates for a refund. It has no
  /// money effect of its own and changes only through its original.
  bool get isRefundEntry =>
      type == TransactionType.refund || linkKind == 'refund';

  /// The fixed direction of the type, else the chosen one.
  Direction? get effectiveDirection => type.fixedDirection ?? direction;

  bool get isInflow => effectiveDirection != Direction.outflow;

  Balance get balance => Balance(
    total: totalMinor,
    paid: paidMinor,
    refunded: refundedMinor,
    credited: creditedMinor,
  );

  /// Whether payments, refunds and credits apply at all.
  bool get isSettleable => type.settleable && !isRefundEntry;

  /// Computed, never stored: see `LedgerMath.isOverdue`.
  bool isOverdue(String today) => LedgerMath.isOverdue(
    status: status,
    outstanding: outstandingMinor,
    dueDate: dueDate,
    today: today,
  );

  /// The best one-line name: description, else party, else category, else
  /// the type.
  String get title {
    for (final candidate in [description, partyName, categoryName]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return type.label;
  }

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    direction,
    categoryId,
    categoryName,
    partyId,
    partyName,
    projectId,
    projectName,
    description,
    reference,
    notes,
    paymentMethod,
    date,
    dueDate,
    receiptDate,
    lineItems,
    totalMinor,
    paidMinor,
    refundedMinor,
    creditedMinor,
    effectiveMinor,
    outstandingMinor,
    paymentStatus,
    isOpen,
    customFields,
    searchTokens,
    linkedTransactionId,
    linkKind,
    settlementId,
    version,
    createdBy,
    createdAt,
    updatedAt,
    updatedBy,
    confirmedAt,
    confirmedBy,
    cancelledAt,
    cancelledBy,
    cancelReason,
    hasPendingWrites,
  ];
}
