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
    this.queued = const [],
    this.actionQueued = false,
  });

  final String? businessId;
  final String? transactionId;
  final Role role;

  /// The cloud is reachable: online and Cloud sync on. Money actions work
  /// either way (queued when not); issuing documents needs it.
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

  /// This user's actions on this transaction still waiting in the outbox,
  /// oldest first. Not reflected in [transaction]: the balance on screen is
  /// the server's until they are applied.
  final List<OutboxEntry> queued;

  /// The last action was queued rather than applied.
  final bool actionQueued;

  bool get hasQueued => queued.isNotEmpty;

  SyncMark get syncMark => SyncMark.of(queued);

  /// What the queued actions will do, for checking new settlements.
  PendingSettlements get pending => PendingSettlements.of(queued);

  /// A draft whose confirm is queued: money can already be recorded
  /// against it (queued behind the confirm).
  bool get confirmQueued => pending.confirmQueued;

  bool _isQueued(OutboxKind kind) => queued.any((entry) => entry.kind == kind);

  bool get isOverdue => transaction?.isOverdue(today) ?? false;

  bool get showsAudit => role.canDoFinancial;

  /// Why [action] is not available, or `null` when it is. Drives both the
  /// action bar (hidden or disabled with the reason) and the cubit's guards.
  String? blockedReason(DetailAction action) {
    final tx = transaction;
    if (tx == null) return 'Still loading.';
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
        if (_isQueued(OutboxKind.confirm)) {
          return 'A confirm is already waiting to sync.';
        }
        return null;
      case DetailAction.cancel:
        if (!role.canDoFinancial) return 'Only admins and owners can cancel.';
        if (_isQueued(OutboxKind.cancel)) {
          return 'A cancel is already waiting to sync.';
        }
        return tx.cancelBlockedReason(pending: pending);
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
        return null;
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
    // Offline or sync off is fine: the settlement is queued.
    return tx.settlementUnavailableReason(kind, pending: pending);
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
    List<OutboxEntry>? queued,
    bool? actionQueued,
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
    queued: queued ?? this.queued,
    actionQueued: actionQueued ?? this.actionQueued,
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
    queued,
    actionQueued,
  ];
}
