import 'dart:typed_data';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_query_plan.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';

/// Transactions of one business (ARCHITECTURE §2, §4, §5).
///
/// * Drafts are written straight to Firestore, offline-first
///   (`LocalFirstWriter`): they queue while offline and the rules check
///   them on sync.
/// * Everything that moves money is a callable. Callables are refused up
///   front while offline. Each takes the caller's `requestId`: one per user
///   action, **reused** for a retry of the same action, so a timed-out call
///   that did land is not applied twice.
abstract class TransactionRepository {
  const TransactionRepository();

  /// A fresh document id, available offline. A new draft gets one before it
  /// is saved, so attachments can be uploaded under it.
  String newTransactionId(String businessId);

  /// A live window of up to [limit] entries for [filter]: an indexed query
  /// (`TransactionQueryPlan`), then the rest of the filter and the sort on
  /// the device. [today] (`yyyy-MM-dd`) decides overdue.
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

  /// Audit entries for one entity, newest first. Admin and owner only: the
  /// rules refuse everyone else (`AppErrorKind.permissionDenied`).
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

  Future<AppResult<ConfirmResult>> confirm(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    bool settleNow = false,
    String? settleDate,
    String? settleMethod,
  });

  /// [changes] holds only the keys that changed (see
  /// `TransactionDraft.changesFrom`).
  Future<AppResult<MutationResult>> editConfirmed(
    String businessId,
    String transactionId, {
    required String requestId,
    required int expectedVersion,
    required Map<String, Object?> changes,
  });

  Future<AppResult<MutationResult>> cancel(
    String businessId,
    String transactionId, {
    required String requestId,
    int? expectedVersion,
    String? reason,
  });

  Future<AppResult<SettlementResult>> recordSettlement(
    String businessId,
    String transactionId, {
    required String requestId,
    required SettlementKind kind,
    required int amountMinor,
    required String date,
    String? method,
    String? note,
    int? expectedVersion,
  });

  /// Uploads to `businesses/{bid}/attachments/{tid}/{file}` and returns the
  /// storage path. Needs a connection.
  Future<AppResult<String>> uploadAttachment(
    String businessId,
    String transactionId,
    PickedAttachment file,
  );

  /// The bytes of a stored attachment, for preview.
  Future<AppResult<Uint8List>> downloadAttachment(String path);
}
