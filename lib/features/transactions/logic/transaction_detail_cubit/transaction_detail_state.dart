part of 'transaction_detail_cubit.dart';

enum DetailAction { confirm, confirmPaid, cancel, delete, duplicate, edit }

class TransactionDetailState extends Equatable {
  const TransactionDetailState({
    this.businessId,
    this.transactionId,
    this.role = Role.viewer,
    this.online = true,
    this.today = '',
    this.transaction,
    this.settlements = const [],
    this.linked = const [],
    this.audit,
    this.fields = const [],
    this.loadStatus = const Status.initial(),
    this.settlementsStatus = const Status.initial(),
    this.auditStatus = const Status.initial(),
    this.action,
    this.actionStatus = const Status.initial(),
    this.removed = false,
    this.duplicatedId,
  });

  final String? businessId;
  final String? transactionId;
  final Role role;
  final bool online;

  /// `yyyy-MM-dd`.
  final String today;
  final LedgerTransaction? transaction;

  /// Newest first.
  final List<Settlement> settlements;

  /// Refund entries created against this transaction.
  final List<LedgerTransaction> linked;

  /// `null` when not loaded or not visible to this role.
  final List<AuditEntry>? audit;

  /// For custom field labels.
  final List<CustomField> fields;
  final Status loadStatus;
  final Status settlementsStatus;
  final Status auditStatus;

  /// The action [actionStatus] belongs to.
  final DetailAction? action;
  final Status actionStatus;

  /// The document is gone (deleted draft): the screen should close.
  final bool removed;

  /// Set after [TransactionDetailCubit.duplicate] succeeds.
  final String? duplicatedId;

  bool get isOverdue => transaction?.isOverdue(today) ?? false;

  bool get showsAudit => role.canDoFinancial;

  /// Why [action] is not available, or `null` when it is. Drives both the
  /// action bar (hidden or disabled with the reason) and the cubit's guards.
  String? blockedReason(DetailAction action) {
    final tx = transaction;
    if (tx == null) return 'Still loading.';
    String? needsOnline() =>
        online ? null : "You're offline. This needs a connection.";
    switch (action) {
      case DetailAction.confirm || DetailAction.confirmPaid:
        if (!tx.isDraft) return 'Only drafts can be confirmed.';
        if (!role.canDoFinancial) {
          return 'Only admins and owners can confirm.';
        }
        if (action == DetailAction.confirmPaid &&
            (!tx.type.settleable || tx.type == TransactionType.payment)) {
          return 'This type is not settled on confirm.';
        }
        return needsOnline();
      case DetailAction.cancel:
        if (!role.canDoFinancial) return 'Only admins and owners can cancel.';
        return tx.cancelBlockedReason() ?? needsOnline();
      case DetailAction.delete:
        if (!tx.isDraft) return 'Only drafts can be deleted.';
        if (!role.canEditConfig) return 'Viewers cannot delete drafts.';
        return null;
      case DetailAction.duplicate:
        if (!role.canEditConfig) return 'Viewers cannot record transactions.';
        if (tx.isRefundEntry) {
          return 'Refund entries are created from their original.';
        }
        return null;
      case DetailAction.edit:
        if (tx.isCancelled) return 'Cancelled transactions are read-only.';
        if (tx.isRefundEntry) {
          return 'A refund entry changes through its original transaction.';
        }
        if (tx.isDraft) {
          return role.canEditConfig ? null : 'Viewers cannot edit.';
        }
        if (!role.canDoFinancial) {
          return 'Only admins and owners can change a confirmed transaction.';
        }
        return needsOnline();
    }
  }

  bool can(DetailAction action) => blockedReason(action) == null;

  /// Why [kind] cannot be recorded now, or `null` when it can.
  String? kindUnavailableReason(SettlementKind kind) {
    final tx = transaction;
    if (tx == null) return 'Still loading.';
    if (!role.canDoFinancial) {
      return 'Only admins and owners can record money.';
    }
    return tx.settlementUnavailableReason(kind) ??
        (online ? null : "You're offline. Recording money needs a connection.");
  }

  bool get canSettleAny => SettlementKind.values.any(
    (kind) => kindUnavailableReason(kind) == null,
  );

  TransactionDetailState copyWith({
    Role? role,
    bool? online,
    String? today,
    LedgerTransaction? transaction,
    List<Settlement>? settlements,
    List<LedgerTransaction>? linked,
    List<AuditEntry>? audit,
    List<CustomField>? fields,
    Status? loadStatus,
    Status? settlementsStatus,
    Status? auditStatus,
    DetailAction? Function()? action,
    Status? actionStatus,
    bool? removed,
    String? Function()? duplicatedId,
  }) => TransactionDetailState(
    businessId: businessId,
    transactionId: transactionId,
    role: role ?? this.role,
    online: online ?? this.online,
    today: today ?? this.today,
    transaction: transaction ?? this.transaction,
    settlements: settlements ?? this.settlements,
    linked: linked ?? this.linked,
    audit: audit ?? this.audit,
    fields: fields ?? this.fields,
    loadStatus: loadStatus ?? this.loadStatus,
    settlementsStatus: settlementsStatus ?? this.settlementsStatus,
    auditStatus: auditStatus ?? this.auditStatus,
    action: action == null ? this.action : action(),
    actionStatus: actionStatus ?? this.actionStatus,
    removed: removed ?? this.removed,
    duplicatedId: duplicatedId == null ? this.duplicatedId : duplicatedId(),
  );

  @override
  List<Object?> get props => [
    businessId,
    transactionId,
    role,
    online,
    today,
    transaction,
    settlements,
    linked,
    audit,
    fields,
    loadStatus,
    settlementsStatus,
    auditStatus,
    action,
    actionStatus,
    removed,
    duplicatedId,
  ];
}
