import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_query_plan.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';

/// Transactions of one business (ARCHITECTURE §2, §4, §5).
///
/// * Reads come from the on-device store, kept up to date by the sync
///   engine.
/// * Drafts are written to the device first and queued in the outbox
///   (`LocalWriter`); row level security checks them when they sync.
/// * Everything that moves money is an RPC. When the cloud is
///   unavailable (offline, or Cloud sync off) the action is queued in the
///   outbox instead and answered with [Queued]; the server re-validates it
///   on replay. Each takes the caller's `requestId`: one per user action,
///   **reused** for a retry of the same action and by the replay, so an
///   action is applied at most once. `label` is how a queued action is
///   listed ("Payment ₹1,200.00 · Cement bags").
abstract class TransactionRepository {
  const TransactionRepository();

  /// A fresh row id (a uuid), available offline. A new draft gets one
  /// before it is saved.
  String newTransactionId(String businessId);

  /// A live window of up to [limit] entries for [filter], from the
  /// on-device store. [today] (`yyyy-MM-dd`) decides overdue.
  Stream<AppResult<TransactionPage>> watchTransactions(
    String businessId,
    TransactionFilter filter, {
    required int limit,
    required String today,
  });

  /// One entry; `null` once it no longer exists (a deleted draft).
  Stream<AppResult<LedgerTransaction?>> watchTransaction(
    String businessId,
    String transactionId,
  );

  /// Payments, refunds and credits, newest first.
  Stream<AppResult<List<Settlement>>> watchSettlements(
    String businessId,
    String transactionId,
  );

  /// The refund entries created against [transactionId], newest first.
  Stream<AppResult<List<LedgerTransaction>>> watchLinked(
    String businessId,
    String transactionId,
  );

  /// Audit entries for one entity, newest first. Admin and owner only:
  /// nobody else's device holds any (empty).
  Stream<AppResult<List<AuditEntry>>> watchAudit(
    String businessId,
    String entityId,
  );

  /// Writes a new draft under `draft.id`. With [awaitServer] the result
  /// waits for the server (used right before a confirm, which reads the
  /// stored draft); otherwise it succeeds as soon as the write is queued.
  Future<AppResult<void>> createDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  });

  /// Replaces a draft's editable fields. Only allowed while it is a draft.
  Future<AppResult<void>> updateDraft(
    String businessId,
    TransactionDraft draft, {
    bool awaitServer = false,
  });

  Future<AppResult<void>> deleteDraft(String businessId, String transactionId);

  /// Copies [source] as a new draft dated [date]. Returns the new id.
  Future<AppResult<String>> duplicate(
    String businessId,
    LedgerTransaction source, {
    required String date,
  });

  Future<AppResult<ActionOutcome<ConfirmResult>>> confirm(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    bool settleNow = false,
    String? settleDate,
    String? settleMethod,
    String label = '',
  });

  /// [changes] holds only the keys that changed (see
  /// `TransactionDraft.changesFrom`).
  Future<AppResult<ActionOutcome<MutationResult>>> editConfirmed(
    String businessId,
    String transactionId, {
    required String requestId,
    required int expectedVersion,
    required Map<String, Object?> changes,
    String label = '',
  });

  Future<AppResult<ActionOutcome<MutationResult>>> cancel(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    String? reason,
    String label = '',
  });

  Future<AppResult<ActionOutcome<SettlementResult>>> recordSettlement(
    String businessId,
    String transactionId, {
    required String requestId,
    required SettlementKind kind,
    required int amountMinor,
    required String date,
    String? method,
    String? note,
    int? expectedVersion,
    String label = '',
  });

  /// The signed-in user's queued actions for this business (oldest first),
  /// live: what the outbox still has to send.
  Stream<List<OutboxEntry>> watchQueued(String businessId);

  /// Pull-to-refresh: asks the server for what changed (other devices,
  /// other members). Completes when done, or at once when unreachable.
  Future<void> refresh() async {}
}
