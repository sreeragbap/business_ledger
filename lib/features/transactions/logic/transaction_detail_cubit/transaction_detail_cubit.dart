import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/close_guard.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/pending_settlements.dart';
import 'package:business_ledger/features/transactions/domain/models/queue_labels.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement_rules.dart';
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart';
import 'package:business_ledger/features/transactions/logic/request_tracker.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'transaction_detail_state.dart';

/// One transaction, live: the document, its settlements, the refund entries
/// linked to it and (for admins) its audit history, plus the state-changing
/// actions: confirm, cancel, delete a draft, duplicate.
///
/// Settlements are recorded through `SettlementFormCubit`; this cubit
/// answers what is possible ([TransactionDetailState.kindUnavailableReason],
/// [settlementViolation], [previewSettlement]) with `LedgerMath`, before
/// anything reaches the server.
///
/// Money actions work offline and with Cloud sync off: they are queued and
/// listed under the balance ([TransactionDetailState.queued]) until the
/// server applies them. The balance shown is always the server's.
@injectable
class TransactionDetailCubit extends Cubit<TransactionDetailState>
    with CloseGuard<TransactionDetailState> {
  TransactionDetailCubit(
    this._repository,
    this._fields,
    this._connectivity, {
    @ignoreParam String Function()? nextRequestId,
    @ignoreParam DateTime Function()? now,
  }) : _requests = RequestTracker(nextRequestId),
       _now = now ?? DateTime.now,
       super(const TransactionDetailState());

  final TransactionRepository _repository;
  final CustomFieldRepository _fields;
  final CloudAvailability _connectivity;
  final RequestTracker _requests;
  final DateTime Function() _now;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  StreamSubscription<Object?>? _audit;
  Currency _currency = Currency.inr;

  Future<void> start({
    required String businessId,
    required String transactionId,
    required Role role,
    Currency currency = Currency.inr,
  }) async {
    await _cancelAll();
    if (isClosing) return;
    _currency = currency;
    emit(
      TransactionDetailState(
        businessId: businessId,
        transactionId: transactionId,
        role: role,
        online: _connectivity.isOnline,
        today: LedgerDates.today(_now()),
        loadStatus: const Status.loading(),
      ),
    );
    _subscriptions
      ..add(_connectivity.onlineChanges.listen(_onOnline))
      ..add(
        _repository
            .watchTransaction(businessId, transactionId)
            .listen(_onTransaction),
      )
      ..add(
        _repository
            .watchSettlements(businessId, transactionId)
            .listen(
              (result) => emit(
                result.when(
                  success: (items) => state.copyWith(
                    settlements: items,
                    settlementsStatus: const Status.success(),
                  ),
                  failure: (error) => state.copyWith(
                    settlementsStatus: Status.fromException(error),
                  ),
                ),
              ),
            ),
      )
      ..add(
        _repository.watchLinked(businessId, transactionId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(linked: data));
          }
        }),
      )
      ..add(
        _repository.watchQueued(businessId).listen((entries) {
          final mine = [
            for (final entry in entries)
              if (entry.transactionId == transactionId) entry,
          ];
          if (!isClosed) emit(state.copyWith(queued: mine));
        }),
      )
      ..add(
        _fields.watchFields(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(fields: data));
          }
        }),
      );
    _watchAudit();
  }

  /// Follows a role change (a promotion shows the history; a demotion hides
  /// the actions).
  void updateRole(Role role) {
    if (role == state.role) return;
    emit(state.copyWith(role: role));
    _watchAudit();
  }

  /// The audit log is admin+ by the rules: others never ask.
  void _watchAudit() {
    final businessId = state.businessId;
    final id = state.transactionId;
    if (businessId == null || id == null) return;
    if (!state.role.canDoFinancial) {
      unawaited(_audit?.cancel());
      _audit = null;
      return;
    }
    if (_audit != null) return;
    emit(state.copyWith(auditStatus: const Status.loading()));
    _audit = _repository.watchAudit(businessId, id).listen((result) {
      switch (result) {
        case Success(:final data):
          emit(
            state.copyWith(audit: data, auditStatus: const Status.success()),
          );
        case Failure(:final error):
          // Permission denied (a demotion racing the stream) hides the
          // section instead of showing an error.
          emit(
            state.copyWith(
              audit: error.kind == AppErrorKind.permissionDenied
                  ? const []
                  : null,
              auditStatus: error.kind == AppErrorKind.permissionDenied
                  ? const Status.success()
                  : Status.fromException(error),
            ),
          );
      }
    });
  }

  void _onOnline(bool online) {
    if (!isClosed && online != state.online) {
      emit(state.copyWith(online: online));
    }
  }

  void _onTransaction(AppResult<LedgerTransaction?> result) {
    switch (result) {
      case Success(data: null):
        emit(
          state.copyWith(
            removed: true,
            loadStatus: const Status.failure(
              'This transaction no longer exists.',
            ),
          ),
        );
      case Success(data: final LedgerTransaction tx):
        emit(
          state.copyWith(
            transaction: tx,
            today: LedgerDates.today(_now()),
            loadStatus: const Status.success(),
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(loadStatus: Status.fromException(error)));
    }
  }

  // --- Settlement checks (no server call) -----------------------------------

  /// Why [amount] of [kind] would be refused, per `LedgerMath`, counting
  /// the settlements already queued for this transaction.
  LedgerViolation? settlementViolation(SettlementKind kind, int amount) {
    final tx = state.transaction;
    if (tx == null) return LedgerViolation.notConfirmed;
    return tx.checkSettlement(kind, amount, pending: state.pending);
  }

  /// The balance after the queued actions and [amount] of [kind], or
  /// `null` when it would be refused.
  Balance? previewSettlement(SettlementKind kind, int amount) {
    final tx = state.transaction;
    if (tx == null || settlementViolation(kind, amount) != null) return null;
    return tx.previewSettlement(kind, amount, pending: state.pending);
  }

  // --- Actions ---------------------------------------------------------------

  bool _guard(DetailAction action) {
    if (state.actionStatus.isLoading) return false;
    final reason = state.blockedReason(action);
    if (reason == null) return true;
    emit(
      state.copyWith(
        action: () => action,
        actionStatus: Status.failure(reason),
      ),
    );
    return false;
  }

  Future<void> confirm({bool settleNow = false}) async {
    final action = settleNow ? DetailAction.confirmPaid : DetailAction.confirm;
    if (!_guard(action)) return;
    final tx = state.transaction!;
    // What the server will refuse anyway, explained without the round trip.
    final amount = LedgerMath.checkAmount(tx.totalMinor);
    final problem = switch (tx) {
      _ when amount != null => amount.message,
      _ when tx.effectiveDirection == null =>
        'Choose whether money is coming in or going out: edit the draft.',
      _ when tx.categoryId == null && tx.type != TransactionType.payment =>
        'Choose a category: edit the draft first.',
      _ => null,
    };
    if (problem != null) {
      emit(
        state.copyWith(
          action: () => action,
          actionStatus: Status.failure(problem),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        action: () => action,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await _repository.confirm(
      state.businessId!,
      tx.id,
      requestId: _requests.idFor('confirm:${tx.id}:$settleNow'),
      expectedVersion: tx.version,
      settleNow: settleNow,
      settleDate: settleNow ? tx.date : null,
      settleMethod: settleNow ? tx.paymentMethod : null,
      label: QueueLabels.confirm(
        tx.totalMinor,
        _currency,
        tx.title,
        settleNow: settleNow,
      ),
    );
    _finish(
      result,
      success: (confirmed) =>
          confirmed.settlementId != null ? 'Confirmed and paid.' : 'Confirmed.',
    );
  }

  Future<void> cancel({String? reason}) async {
    if (!_guard(DetailAction.cancel)) return;
    final tx = state.transaction!;
    emit(
      state.copyWith(
        action: () => DetailAction.cancel,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await _repository.cancel(
      state.businessId!,
      tx.id,
      requestId: _requests.idFor('cancel:${tx.id}:${tx.version}'),
      expectedVersion: tx.version,
      reason: reason,
      label: QueueLabels.cancel(tx.title),
    );
    _finish(
      result,
      success: (done) => done.voidedDocuments > 0
          ? 'Cancelled. ${done.voidedDocuments} document'
                '${done.voidedDocuments == 1 ? ' was' : 's were'} voided.'
          : 'Cancelled.',
    );
  }

  Future<void> deleteDraft() async {
    if (!_guard(DetailAction.delete)) return;
    emit(
      state.copyWith(
        action: () => DetailAction.delete,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await _repository.deleteDraft(
      state.businessId!,
      state.transaction!.id,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        removed: result.isSuccess,
        actionStatus: result.when(
          success: (_) => const Status.success(message: 'Draft deleted.'),
          failure: Status.fromException,
        ),
      ),
    );
  }

  /// Copies the entry as a new draft dated today.
  Future<void> duplicate() async {
    if (!_guard(DetailAction.duplicate)) return;
    emit(
      state.copyWith(
        action: () => DetailAction.duplicate,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await _repository.duplicate(
      state.businessId!,
      state.transaction!,
      date: state.today,
    );
    if (isClosed) return;
    emit(
      result.when(
        success: (id) => state.copyWith(
          duplicatedId: () => id,
          actionStatus: const Status.success(message: 'Copied as a draft.'),
        ),
        failure: (error) =>
            state.copyWith(actionStatus: Status.fromException(error)),
      ),
    );
  }

  /// A queued action is a success too: it is safe on the device and will be
  /// applied (or flagged) when synced. Either way the outcome is known, so
  /// the next tap is a new action with a new requestId.
  void _finish<T>(
    AppResult<ActionOutcome<T>> result, {
    required String Function(T data) success,
  }) {
    if (isClosed) return;
    _requests.settle(result.errorOrNull);
    emit(
      state.copyWith(
        actionQueued: result.dataOrNull?.isQueued ?? false,
        actionStatus: result.when(
          success: (outcome) => Status.success(
            message: switch (outcome) {
              Applied(:final result) => success(result),
              Queued() => QueueLabels.queuedMessage,
            },
          ),
          failure: Status.fromException,
        ),
      ),
    );
  }

  Future<void> _cancelAll() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _audit?.cancel();
    _audit = null;
  }

  @override
  Future<void> close() async {
    beginClose();
    await _cancelAll();
    return super.close();
  }
}
