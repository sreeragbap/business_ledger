import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/const/standard_field.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/domain/repository/category_repository.dart';
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/domain/repository/party_repository.dart';
import 'package:business_ledger/features/projects/domain/models/project.dart';
import 'package:business_ledger/features/projects/domain/repository/project_repository.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/domain/models/queue_labels.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_draft.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart';
import 'package:business_ledger/features/transactions/logic/request_tracker.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'transaction_form_state.dart';

/// Create or edit a transaction.
///
/// * A new entry or a draft is saved on the device and queued for upload
///   (works offline).
/// * "Save & confirm" (admin+) saves the draft, waits for the server to
///   have it, then calls `confirmTransaction`; "as paid" adds `settleNow`.
///   Offline or with Cloud sync off the draft is saved locally and the
///   confirm is queued ([TransactionFormOutcome.queued]); the sync engine
///   sends the draft first.
/// * A confirmed entry is changed through `editConfirmedTransaction` with
///   only the changed keys and the `expectedVersion` it was loaded at; a
///   conflict asks the user to reload. Offline it is queued the same way.
///
/// No arithmetic happens here beyond `Money.lineAmount` (via [LineItem]) and
/// `LedgerMath` checks.
@injectable
class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit(
    this._repository,
    this._categories,
    this._fields,
    this._parties,
    this._projects,
    this._connectivity, {
    @ignoreParam String Function()? nextRequestId,
    @ignoreParam DateTime Function()? now,
  }) : _requests = RequestTracker(nextRequestId),
       _now = now ?? DateTime.now,
       super(const TransactionFormState());

  final TransactionRepository _repository;
  final CategoryRepository _categories;
  final CustomFieldRepository _fields;
  final PartyRepository _parties;
  final ProjectRepository _projects;
  final CloudAvailability _connectivity;
  final RequestTracker _requests;
  final DateTime Function() _now;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  int _nextLineKey = 0;

  /// The draft as last sent to `confirmTransaction`. A retry of an unknown
  /// outcome with the draft unchanged skips the re-save: if the first call
  /// did land, the entry is no longer a draft and the save would be refused.
  TransactionDraft? _lastConfirmAttempt;

  String get _today => LedgerDates.today(_now());

  /// Sets up the form. Pass [transactionId] to edit a stored entry, or
  /// [initialType] for a new one.
  Future<void> start({
    required String businessId,
    required Currency currency,
    required Role role,
    required Set<StandardField> enabledFields,
    String? transactionId,
    TransactionType? initialType,
  }) async {
    emit(
      TransactionFormState(
        businessId: businessId,
        currency: currency,
        role: role,
        enabledFields: enabledFields,
        online: _connectivity.isOnline,
        loadStatus: transactionId == null
            ? const Status.success()
            : const Status.loading(),
      ),
    );
    _watchLookups(businessId);

    if (transactionId == null) {
      final type = initialType != null && initialType.isCreatable
          ? initialType
          : TransactionType.expense;
      final blank = TransactionDraft.blank(
        id: _repository.newTransactionId(businessId),
        type: type,
        date: _today,
      );
      emit(state.copyWith(draft: blank, initialDraft: blank));
      return;
    }
    await _load(businessId, transactionId);
  }

  void _watchLookups(String businessId) {
    _subscriptions
      ..add(_connectivity.onlineChanges.listen(_onOnline))
      ..add(
        _categories.watchCategories(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(categories: data));
          }
        }),
      )
      ..add(
        _fields.watchFields(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(fields: data));
          }
        }),
      )
      ..add(
        _parties.watchParties(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(parties: data));
          }
        }),
      )
      ..add(
        _projects.watchProjects(businessId).listen((result) {
          if (result case Success(:final data)) {
            emit(state.copyWith(projects: data));
          }
        }),
      );
  }

  void _onOnline(bool online) {
    if (!isClosed && online != state.online) {
      emit(state.copyWith(online: online));
    }
  }

  Future<void> _load(String businessId, String transactionId) async {
    emit(state.copyWith(loadStatus: const Status.loading()));
    final result = await _repository
        .watchTransaction(businessId, transactionId)
        .map<AppResult<LedgerTransaction?>?>((result) => result)
        .firstWhere((_) => true, orElse: () => null);
    if (result == null) return;
    if (isClosed) return;
    switch (result) {
      case Failure(:final error):
        emit(state.copyWith(loadStatus: Status.fromException(error)));
      case Success(data: null):
        emit(
          state.copyWith(
            loadStatus: const Status.failure(
              'That transaction no longer exists.',
            ),
          ),
        );
      case Success(data: final LedgerTransaction tx):
        if (tx.isCancelled || tx.isRefundEntry) {
          emit(
            state.copyWith(
              original: tx,
              loadStatus: Status.failure(
                tx.isCancelled
                    ? 'A cancelled transaction cannot be edited.'
                    : 'A refund entry changes through its original '
                          'transaction.',
              ),
            ),
          );
          return;
        }
        final draft = TransactionDraft.fromTransaction(
          tx,
          fallbackDate: _today,
        );
        emit(
          state.copyWith(
            mode: tx.isDraft
                ? TransactionFormMode.editDraft
                : TransactionFormMode.editConfirmed,
            original: tx,
            draft: draft,
            initialDraft: draft,
            persisted: true,
            lineKeys: _keysFor(draft.lineItems.length),
            errors: const {},
            saveStatus: const Status.initial(),
            loadStatus: const Status.success(),
          ),
        );
    }
  }

  /// Discards local edits and loads the latest stored version (after a
  /// conflict).
  Future<void> reload() async {
    final businessId = state.businessId;
    final id = state.draft?.id ?? state.original?.id;
    if (businessId == null || id == null) return;
    _requests.settle(null);
    await _load(businessId, id);
  }

  List<int> _keysFor(int count) => [
    for (var i = 0; i < count; i++) _nextLineKey++,
  ];

  // --- Editing ---------------------------------------------------------------

  void _update(TransactionDraft Function(TransactionDraft draft) change) {
    final draft = state.draft;
    if (draft == null) return;
    emit(
      state.copyWith(
        draft: change(draft),
        saveStatus: state.saveStatus.isFailure ? const Status.initial() : null,
        outcome: () => null,
      ),
    );
  }

  void _clearError(String key) {
    if (!state.errors.containsKey(key)) return;
    emit(state.copyWith(errors: {...state.errors}..remove(key)));
  }

  /// Changes the type. A fixed direction replaces the chosen one; a
  /// category that no longer fits the direction is cleared. Type is fixed
  /// once confirmed.
  void setType(TransactionType type) {
    if (state.isConfirmedEdit || !type.isCreatable) return;
    final direction = type.fixedDirection ?? state.draft?.direction;
    _update(
      (draft) => _fitCategory(
        draft.copyWith(type: type, direction: () => direction),
      ),
    );
    _clearError('direction');
  }

  /// For payment and adjustment, which go either way.
  void setDirection(Direction direction) {
    if (state.isConfirmedEdit || state.type.fixedDirection != null) return;
    _update(
      (draft) => _fitCategory(draft.copyWith(direction: () => direction)),
    );
    _clearError('direction');
  }

  TransactionDraft _fitCategory(TransactionDraft draft) {
    final direction = draft.resolvedDirection;
    final category = state.categories
        ?.where((c) => c.id == draft.categoryId)
        .firstOrNull;
    if (category == null || direction == null) return draft;
    if (category.kind.allows(direction)) return draft;
    return draft.copyWith(categoryId: () => null, categoryName: () => null);
  }

  void setCategory(Category? category) {
    _update(
      (draft) => draft.copyWith(
        categoryId: () => category?.id,
        categoryName: () => category?.name,
      ),
    );
    _clearError('categoryId');
  }

  void setParty(Party? party) => _update(
    (draft) => draft.copyWith(
      partyId: () => party?.id,
      partyName: () => party?.name,
    ),
  );

  void setProject(Project? project) => _update(
    (draft) => draft.copyWith(
      projectId: () => project?.id,
      projectName: () => project?.name,
    ),
  );

  /// Creates a party from inside the form and selects it.
  Future<void> createParty(Party party) async {
    final businessId = state.businessId;
    if (businessId == null) return;
    final result = await _parties.create(businessId, party);
    switch (result) {
      case Success(data: final id):
        setParty(party.copyWith(id: id));
      case Failure(:final error):
        emit(state.copyWith(saveStatus: Status.fromException(error)));
    }
  }

  void setDescription(String value) {
    _update((draft) => draft.copyWith(description: value));
    _clearError('description');
  }

  void setReference(String value) =>
      _update((draft) => draft.copyWith(reference: value));

  void setNotes(String value) =>
      _update((draft) => draft.copyWith(notes: value));

  void setPaymentMethod(String value) =>
      _update((draft) => draft.copyWith(paymentMethod: value));

  void setDate(String day) {
    _update((draft) => draft.copyWith(date: day));
    _clearError('date');
    _clearError('dueDate');
  }

  void setDueDate(String? day) {
    _update((draft) => draft.copyWith(dueDate: () => day));
    _clearError('dueDate');
  }

  /// Switches between a single amount and line items, carrying the amount
  /// across: an amount becomes one line of 1 × amount; lines become their
  /// total.
  void setUseLineItems({required bool value}) {
    final draft = state.draft;
    if (draft == null || draft.useLineItems == value) return;
    if (value) {
      final lines = draft.lineItems.isNotEmpty
          ? draft.lineItems
          : [LineItem.of(rateMinor: draft.totalMinor ?? 0)];
      emit(state.copyWith(lineKeys: _keysFor(lines.length)));
      _update((d) => d.copyWith(useLineItems: true, lineItems: lines));
    } else {
      final total = LineItem.total(draft.lineItems);
      _update(
        (d) => d.copyWith(
          useLineItems: false,
          totalMinor: () => total == 0 ? null : total,
        ),
      );
    }
    _clearError('lineItems');
    _clearError('totalMinor');
  }

  void addLine() {
    final draft = state.draft;
    if (draft == null ||
        draft.lineItems.length >= TransactionDraft.maxLineItems) {
      return;
    }
    emit(state.copyWith(lineKeys: [...state.lineKeys, ..._keysFor(1)]));
    _update((d) => d.copyWith(lineItems: [...d.lineItems, LineItem.of()]));
    _clearError('lineItems');
  }

  void updateLine(
    int index, {
    String? description,
    int? quantityMilli,
    int? rateMinor,
  }) {
    final lines = state.draft?.lineItems;
    if (lines == null || index < 0 || index >= lines.length) return;
    final next = [...lines];
    next[index] = lines[index].copyWith(
      description: description,
      quantityMilli: quantityMilli,
      rateMinor: rateMinor,
    );
    _update((d) => d.copyWith(lineItems: next));
    _clearError('lineItems');
    _clearError('totalMinor');
  }

  void removeLine(int index) {
    final lines = state.draft?.lineItems;
    if (lines == null || index < 0 || index >= lines.length) return;
    emit(
      state.copyWith(lineKeys: [...state.lineKeys]..removeAt(index)),
    );
    _update((d) => d.copyWith(lineItems: [...lines]..removeAt(index)));
  }

  void setTotal(int? minor) {
    _update((draft) => draft.copyWith(totalMinor: () => minor));
    _clearError('totalMinor');
  }

  void setCustomField(String fieldId, Object? value) {
    _update(
      (draft) => draft.copyWith(
        customFields: {...draft.customFields, fieldId: value},
      ),
    );
    _clearError('customFields.$fieldId');
  }

  // --- Validation ------------------------------------------------------------

  /// Field errors for the current draft. [forConfirm] adds everything the
  /// server checks on confirm (`confirmTransaction` / `checkDates` /
  /// `readReferences` / `checkRequiredFields`).
  Map<String, String> validate({required bool forConfirm}) {
    final draft = state.draft;
    if (draft == null) return const {};
    final errors = <String, String>{};
    if (draft.description.trim().length >
        TransactionDraft.maxDescriptionLength) {
      errors['description'] =
          'Keep the description under '
          '${TransactionDraft.maxDescriptionLength} characters.';
    }
    if (draft.reference.trim().length > TransactionDraft.maxReferenceLength) {
      errors['reference'] =
          'Keep the reference under '
          '${TransactionDraft.maxReferenceLength} characters.';
    }
    if (draft.notes.trim().length > TransactionDraft.maxNotesLength) {
      errors['notes'] = 'The notes are too long.';
    }
    if (!LedgerDates.isValid(draft.date)) errors['date'] = 'Choose a date.';
    final due = draft.dueDate;
    if (due != null && due.compareTo(draft.date) < 0) {
      errors['dueDate'] = 'The due date cannot be before the transaction date.';
    }
    if (draft.useLineItems &&
        draft.lineItems.length > TransactionDraft.maxLineItems) {
      errors['lineItems'] = 'Up to ${TransactionDraft.maxLineItems} lines.';
    }
    if (draft.total > Money.maxMinor) {
      errors['totalMinor'] = LedgerViolation.amountTooLarge.message;
    }
    if (!forConfirm) return errors;

    if (draft.resolvedDirection == null) {
      errors['direction'] = 'Choose whether money is coming in or going out.';
    }
    final category = state.selectedCategory;
    if (draft.categoryId == null) {
      if (draft.type != TransactionType.payment) {
        errors['categoryId'] = 'Choose a category.';
      }
    } else if (category != null) {
      final direction = draft.resolvedDirection;
      if (category.archived) {
        errors['categoryId'] = 'That category is archived. Choose another.';
      } else if (direction != null && !category.kind.allows(direction)) {
        errors['categoryId'] =
            '"${category.name}" is an ${category.kind.key} category.';
      }
    }
    if (draft.useLineItems) {
      if (draft.lineItems.isEmpty) {
        errors['lineItems'] = 'Add at least one line.';
      }
      for (var i = 0; i < draft.lineItems.length; i++) {
        if (draft.lineItems[i].quantityMilli <= 0) {
          errors['lineItems'] = 'Line ${i + 1}: enter a quantity above zero.';
          break;
        }
      }
    }
    final original = state.original;
    final amountViolation = state.isConfirmedEdit && original != null
        ? LedgerMath.checkTotalEdit(original.balance, draft.total)
        : LedgerMath.checkAmount(draft.total);
    if (amountViolation != null) {
      errors['totalMinor'] = amountViolation.message;
    } else if (state.isConfirmedEdit &&
        original != null &&
        draft.type == TransactionType.payment &&
        draft.total != original.totalMinor) {
      errors['totalMinor'] =
          "A payment entry's amount cannot change. Cancel it and record a "
          'new one.';
    }
    for (final field in state.categoryFields) {
      if (field.required &&
          TransactionDraft.isBlankValue(draft.customFields[field.id])) {
        errors['customFields.${field.id}'] = '${field.label} is required.';
      }
    }
    return errors;
  }

  bool _rejectInvalid({required bool forConfirm}) {
    final errors = validate(forConfirm: forConfirm);
    if (errors.isEmpty) {
      if (state.errors.isNotEmpty) emit(state.copyWith(errors: const {}));
      return false;
    }
    emit(
      state.copyWith(
        errors: errors,
        saveStatus: Status.failure(
          errors.length == 1
              ? errors.values.first
              : 'Check the highlighted fields.',
        ),
      ),
    );
    return true;
  }

  void _fail(AppException error) {
    final field = error.field;
    emit(
      state.copyWith(
        errors: field == null ? null : {...state.errors, field: error.message},
        saveStatus: Status.fromException(error),
      ),
    );
  }

  // --- Saving ----------------------------------------------------------------

  Future<AppResult<void>> _writeDraft({required bool awaitServer}) {
    final businessId = state.businessId!;
    final draft = state.draft!;
    return state.persisted
        ? _repository.updateDraft(businessId, draft, awaitServer: awaitServer)
        : _repository.createDraft(businessId, draft, awaitServer: awaitServer);
  }

  /// Saves as a draft. Works offline: the write is queued.
  Future<void> saveDraft() async {
    if (state.draft == null || state.businessId == null || state.isBusy) {
      return;
    }
    if (!state.canSaveDraft) {
      emit(
        state.copyWith(
          saveStatus: const Status.failure(
            'Viewers cannot record transactions.',
          ),
        ),
      );
      return;
    }
    if (_rejectInvalid(forConfirm: false)) return;
    emit(state.copyWith(saveStatus: const Status.loading()));
    final result = await _writeDraft(awaitServer: false);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            persisted: true,
            outcome: () => TransactionFormOutcome.savedDraft,
            saveStatus: Status.success(
              message: state.online
                  ? 'Draft saved.'
                  : 'Draft saved on this device. It will sync later.',
            ),
          ),
        );
      case Failure(:final error):
        _fail(error);
    }
  }

  /// Saves the draft and confirms it; with [settleNow] the full amount is
  /// recorded as paid in the same server write.
  Future<void> saveAndConfirm({bool settleNow = false}) async {
    final businessId = state.businessId;
    final draft = state.draft;
    if (businessId == null || draft == null || state.isBusy) return;
    if (state.isConfirmedEdit) return;
    final blocked = state.confirmBlockedReason;
    if (blocked != null) {
      emit(state.copyWith(saveStatus: Status.failure(blocked)));
      return;
    }
    if (settleNow && !state.canSettleNow) return;
    if (_rejectInvalid(forConfirm: true)) return;
    emit(state.copyWith(saveStatus: const Status.loading()));

    final key = 'confirm:${draft.id}:$settleNow';
    final isRetry = _requests.isPending(key) && _lastConfirmAttempt == draft;
    if (!isRetry) {
      // The server confirms what is stored, so it must have this version.
      // Offline the draft is saved locally instead and the confirm queued:
      // the sync engine waits for the draft to reach the server first.
      var saved = await _writeDraft(awaitServer: state.online);
      if (isClosed) return;
      if (saved case Failure(:final error) when _mayWait(error)) {
        // The connection dropped mid-save: keep it on the device.
        saved = await _writeDraft(awaitServer: false);
        if (isClosed) return;
      }
      if (saved case Failure(:final error)) {
        _fail(error);
        return;
      }
      emit(state.copyWith(persisted: true));
    }

    final requestId = _requests.idFor(key);
    _lastConfirmAttempt = draft;
    final result = await _repository.confirm(
      businessId,
      draft.id,
      requestId: requestId,
      expectedVersion: state.original?.version ?? 0,
      settleNow: settleNow,
      settleDate: settleNow ? draft.date : null,
      settleMethod: settleNow ? draft.paymentMethod : null,
      label: QueueLabels.confirm(
        draft.total,
        state.currency,
        _titleOf(draft),
        settleNow: settleNow,
      ),
    );
    if (isClosed) return;
    _requests.settle(result.errorOrNull);
    switch (result) {
      case Success(data: Queued()):
        _lastConfirmAttempt = null;
        emit(
          state.copyWith(
            outcome: () => TransactionFormOutcome.queued,
            saveStatus: const Status.success(
              message: QueueLabels.queuedMessage,
            ),
          ),
        );
      case Success(data: Applied(result: final ConfirmResult confirmed)):
        _lastConfirmAttempt = null;
        final paid = confirmed.settlementId != null;
        emit(
          state.copyWith(
            outcome: () => paid
                ? TransactionFormOutcome.confirmedPaid
                : TransactionFormOutcome.confirmed,
            saveStatus: Status.success(
              message: paid ? 'Confirmed and paid.' : 'Confirmed.',
            ),
          ),
        );
      case Failure(:final error):
        _fail(error);
    }
  }

  /// Saves changes to a confirmed entry: only the changed keys, against the
  /// version it was loaded at.
  Future<void> saveConfirmedChanges() async {
    final businessId = state.businessId;
    final draft = state.draft;
    final original = state.original;
    if (businessId == null || draft == null || original == null) return;
    if (!state.isConfirmedEdit || state.isBusy) return;
    final blocked = state.editBlockedReason;
    if (blocked != null) {
      emit(state.copyWith(saveStatus: Status.failure(blocked)));
      return;
    }
    if (_rejectInvalid(forConfirm: true)) return;
    final changes = draft.changesFrom(original);
    if (changes.isEmpty) {
      emit(
        state.copyWith(
          outcome: () => TransactionFormOutcome.edited,
          saveStatus: const Status.success(message: 'Nothing changed.'),
        ),
      );
      return;
    }
    emit(state.copyWith(saveStatus: const Status.loading()));
    final requestId = _requests.idFor(
      'edit:${draft.id}:${original.version}:$changes',
    );
    final result = await _repository.editConfirmed(
      businessId,
      draft.id,
      requestId: requestId,
      expectedVersion: original.version,
      changes: changes,
      label: QueueLabels.edit(_titleOf(draft)),
    );
    if (isClosed) return;
    _requests.settle(result.errorOrNull);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            outcome: () => TransactionFormOutcome.edited,
            saveStatus: Status.success(
              message: data.isQueued
                  ? QueueLabels.queuedMessage
                  : 'Changes saved.',
            ),
          ),
        );
      case Failure(:final error):
        _fail(error);
    }
  }

  /// The connection, not the content: worth keeping the work locally.
  static bool _mayWait(AppException error) =>
      error.kind == AppErrorKind.offline || error.kind == AppErrorKind.timeout;

  static String _titleOf(TransactionDraft draft) {
    for (final candidate in [
      draft.description,
      draft.partyName,
      draft.categoryName,
    ]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return draft.type.label;
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
