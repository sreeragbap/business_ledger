import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement_rules.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart';
import 'package:business_ledger/features/transactions/logic/request_tracker.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'settlement_form_state.dart';

/// The "record payment / refund / credit" sheet.
///
/// Checks the amount with `LedgerMath.checkSettlement` as it is typed and
/// previews the resulting balance; only a passing amount is sent. The
/// transaction stays live underneath, so the `expectedVersion` sent is the
/// one on screen; a conflict (someone settled first) refreshes it and asks
/// the user to check again.
@injectable
class SettlementFormCubit extends Cubit<SettlementFormState> {
  SettlementFormCubit(
    this._repository, {
    @ignoreParam String Function()? nextRequestId,
    @ignoreParam DateTime Function()? now,
  }) : _requests = RequestTracker(nextRequestId),
       _now = now ?? DateTime.now,
       super(const SettlementFormState());

  final TransactionRepository _repository;
  final RequestTracker _requests;
  final DateTime Function() _now;
  StreamSubscription<AppResult<LedgerTransaction?>>? _live;

  static const int maxNoteLength = 500;

  Future<void> start({
    required String businessId,
    required LedgerTransaction transaction,
    SettlementKind? kind,
  }) async {
    await _live?.cancel();
    final initialKind =
        kind ??
        SettlementKind.values.firstWhere(
          transaction.canSettle,
          orElse: () => SettlementKind.payment,
        );
    emit(
      SettlementFormState(
        businessId: businessId,
        transaction: transaction,
        kind: initialKind,
        date: LedgerDates.today(_now()),
        today: LedgerDates.today(_now()),
        method: initialKind == SettlementKind.credit
            ? ''
            : transaction.paymentMethod,
      ),
    );
    _live = _repository.watchTransaction(businessId, transaction.id).listen((
      result,
    ) {
      if (result case Success(data: final LedgerTransaction tx)) {
        emit(state.copyWith(transaction: tx));
      }
    });
  }

  void setKind(SettlementKind kind) {
    if (kind == state.kind) return;
    emit(
      state.copyWith(
        kind: kind,
        // An amount typed for a payment is rarely right for a refund.
        amountMinor: () => null,
        errors: const {},
        submitStatus: const Status.initial(),
      ),
    );
  }

  void setAmount(int? minor) => emit(
    state.copyWith(
      amountMinor: () => minor,
      errors: {...state.errors}..remove('amountMinor'),
      submitStatus: state.submitStatus.isFailure
          ? const Status.initial()
          : null,
    ),
  );

  /// Fills the whole outstanding (or refundable) amount.
  void fillFull() {
    final tx = state.transaction;
    if (tx == null) return;
    setAmount(tx.maxSettlement(state.kind));
  }

  void setDate(String day) => emit(
    state.copyWith(date: day, errors: {...state.errors}..remove('date')),
  );

  void setMethod(String value) => emit(state.copyWith(method: value));

  void setNote(String value) => emit(
    state.copyWith(note: value, errors: {...state.errors}..remove('note')),
  );

  Future<void> submit() async {
    final businessId = state.businessId;
    final tx = state.transaction;
    if (businessId == null || tx == null || state.submitStatus.isLoading) {
      return;
    }
    final amount = state.amountMinor;
    final errors = <String, String>{
      if (amount == null)
        'amountMinor': 'Enter an amount.'
      else if (tx.checkSettlement(state.kind, amount) case final violation?)
        'amountMinor': violation.message,
      if (!LedgerDates.isValid(state.date)) 'date': 'Choose a date.',
      if (state.note.trim().length > maxNoteLength)
        'note': 'Keep the note under $maxNoteLength characters.',
    };
    if (errors.isNotEmpty) {
      emit(
        state.copyWith(
          errors: errors,
          submitStatus: Status.failure(errors.values.first),
        ),
      );
      return;
    }
    emit(
      state.copyWith(errors: const {}, submitStatus: const Status.loading()),
    );
    final key = [
      'settle',
      tx.id,
      state.kind.key,
      amount,
      state.date,
      state.method.trim(),
      state.note.trim(),
    ].join(':');
    final result = await _repository.recordSettlement(
      businessId,
      tx.id,
      requestId: _requests.idFor(key),
      kind: state.kind,
      amountMinor: amount!,
      date: state.date,
      method: state.method,
      note: state.note,
      expectedVersion: tx.version,
    );
    if (isClosed) return;
    _requests.settle(result.errorOrNull);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            result: data,
            submitStatus: Status.success(
              message: '${state.kind.label} recorded.',
            ),
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(
            errors: error.field == null ? null : {error.field!: error.message},
            submitStatus: error.isConflict
                ? Status.failure(
                    'Someone else just changed this transaction. The balance '
                    'is up to date now: check the amount and try again.',
                    error: error,
                  )
                : Status.fromException(error),
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _live?.cancel();
    return super.close();
  }
}
