part of 'transaction_form_cubit.dart';

enum TransactionFormMode {
  /// A new entry, not yet saved.
  create,

  /// A stored draft: saved on the device first, works offline.
  editDraft,

  /// A confirmed entry: changes go through `editConfirmedTransaction`.
  editConfirmed,
}

/// How the form finished, for the screen to navigate and celebrate.
enum TransactionFormOutcome {
  savedDraft,
  confirmed,
  confirmedPaid,
  edited,

  /// Saved on the device; the confirm waits in the outbox until synced.
  queued,
}

class TransactionFormState extends Equatable {
  const TransactionFormState({
    this.businessId,
    this.currency = Currency.inr,
    this.role = Role.viewer,
    this.enabledFields = const {},
    this.online = true,
    this.mode = TransactionFormMode.create,
    this.draft,
    this.initialDraft,
    this.original,
    this.persisted = false,
    this.lineKeys = const [],
    this.categories,
    this.fields = const [],
    this.parties = const [],
    this.projects = const [],
    this.errors = const {},
    this.loadStatus = const Status.initial(),
    this.saveStatus = const Status.initial(),
    this.outcome,
    this.formRevision = 0,
    this.receiptFilled = const {},
  });

  final String? businessId;
  final Currency currency;
  final Role role;
  final Set<StandardField> enabledFields;

  /// The cloud is reachable (online and Cloud sync on). When not, drafts
  /// save locally and confirms / edits are queued.
  final bool online;
  final TransactionFormMode mode;

  /// `null` while an existing entry loads.
  final TransactionDraft? draft;

  /// The draft as the form opened (blank, or the stored entry). Leaving
  /// with [draft] different from it asks before discarding the changes.
  final TransactionDraft? initialDraft;

  /// The user changed something and has not saved it yet.
  bool get hasUnsavedChanges =>
      outcome == null && draft != null && draft != initialDraft;

  /// The stored entry being edited.
  final LedgerTransaction? original;

  /// Whether the draft document exists (decides create vs update).
  final bool persisted;

  /// Stable keys for the line rows, parallel to `draft.lineItems`.
  final List<int> lineKeys;

  /// `null` until loaded.
  final List<Category>? categories;
  final List<CustomField> fields;
  final List<Party> parties;
  final List<Project> projects;

  /// Field errors by key (`categoryId`, `totalMinor`, `customFields.<id>`…).
  final Map<String, String> errors;
  final Status loadStatus;
  final Status saveStatus;
  final TransactionFormOutcome? outcome;

  /// Bumped when the draft changes from outside the fields (a scanned
  /// receipt, its undo): the form rebuilds its fields with the new values.
  final int formRevision;

  /// Field keys (`totalMinor`, `date`, `partyId`…) the last receipt scan
  /// filled, for the form to highlight.
  final Set<String> receiptFilled;

  bool isEnabled(StandardField field) => enabledFields.contains(field);

  Direction? get direction => draft?.resolvedDirection;

  TransactionType get type => draft?.type ?? TransactionType.expense;

  bool get isConfirmedEdit => mode == TransactionFormMode.editConfirmed;

  /// Categories offered: not archived and allowed for the direction.
  List<Category> get availableCategories => [
    for (final category in categories ?? const <Category>[])
      if (!category.archived &&
          (direction == null || category.kind.allows(direction!)))
        category,
  ];

  Category? get selectedCategory {
    final id = draft?.categoryId;
    if (id == null) return null;
    return categories?.where((c) => c.id == id).firstOrNull;
  }

  /// The selected category's custom fields, in its order, skipping archived
  /// ones and ids that no longer resolve.
  List<CustomField> get categoryFields {
    final category = selectedCategory;
    if (category == null) return const [];
    return [
      for (final id in category.fieldIds)
        ?fields.where((f) => f.id == id && !f.archived).firstOrNull,
    ];
  }

  List<Party> get activeParties => [
    for (final party in parties)
      if (!party.archived || party.id == draft?.partyId) party,
  ];

  List<Project> get activeProjects => [
    for (final project in projects)
      if (!project.archived || project.id == draft?.projectId) project,
  ];

  int get total => draft?.total ?? 0;

  /// The active party a receipt's shop name refers to: the same name once
  /// case, spaces and punctuation are ignored, or one name containing the
  /// other. Suppliers for money out (and when undecided), customers for
  /// money in.
  Party? partyMatching(String name) {
    String normalise(String value) =>
        value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final wanted = normalise(name);
    if (wanted.length < 3) return null;
    final kind = direction == Direction.inflow
        ? PartyKind.customer
        : PartyKind.supplier;
    for (final party in activeParties) {
      if (party.archived || !party.kind.matches(kind)) continue;
      final have = normalise(party.name);
      if (have == wanted ||
          (have.length >= 4 &&
              (wanted.contains(have) || have.contains(wanted)))) {
        return party;
      }
    }
    return null;
  }

  bool get isBusy => saveStatus.isLoading;

  bool get canSaveDraft => role.canEditConfig && !isConfirmedEdit;

  /// Why the entry cannot be confirmed from here, or `null`.
  String? get confirmBlockedReason {
    if (!role.canDoFinancial) {
      return 'Only admins and owners can confirm. Save it as a draft for '
          'them to review.';
    }
    return null;
  }

  bool get canConfirm => !isConfirmedEdit && confirmBlockedReason == null;

  /// What the financial buttons do while the cloud is unreachable.
  String? get queueNote => online
      ? null
      : isConfirmedEdit
      ? 'Not syncing right now: the changes are kept on this device and '
            'applied when synced. They may be refused if the transaction '
            'changed meanwhile.'
      : 'Not syncing right now: a confirm is kept on this device and '
            'applied when synced. It may be refused if something changed '
            'meanwhile.';

  /// "Save & confirm as paid": a settleable type that is not already
  /// settled on confirm (payments always are).
  bool get canSettleNow =>
      canConfirm && type.settleable && type != TransactionType.payment;

  /// Why a confirmed entry cannot be changed from here, or `null`.
  String? get editBlockedReason {
    if (!isConfirmedEdit) return null;
    if (!role.canDoFinancial) {
      return 'Only admins and owners can change a confirmed transaction.';
    }
    return null;
  }

  /// Due dates matter only where money can stay outstanding.
  bool get showsDueDate =>
      isEnabled(StandardField.dueDate) &&
      type.settleable &&
      type != TransactionType.payment;

  /// Server conflict: someone changed the entry first.
  bool get hasConflict => saveStatus.error?.isConflict ?? false;

  TransactionFormState copyWith({
    String? businessId,
    Currency? currency,
    Role? role,
    Set<StandardField>? enabledFields,
    bool? online,
    TransactionFormMode? mode,
    TransactionDraft? draft,
    TransactionDraft? initialDraft,
    LedgerTransaction? original,
    bool? persisted,
    List<int>? lineKeys,
    List<Category>? categories,
    List<CustomField>? fields,
    List<Party>? parties,
    List<Project>? projects,
    Map<String, String>? errors,
    Status? loadStatus,
    Status? saveStatus,
    TransactionFormOutcome? Function()? outcome,
    int? formRevision,
    Set<String>? receiptFilled,
  }) => TransactionFormState(
    businessId: businessId ?? this.businessId,
    currency: currency ?? this.currency,
    role: role ?? this.role,
    enabledFields: enabledFields ?? this.enabledFields,
    online: online ?? this.online,
    mode: mode ?? this.mode,
    draft: draft ?? this.draft,
    initialDraft: initialDraft ?? this.initialDraft,
    original: original ?? this.original,
    persisted: persisted ?? this.persisted,
    lineKeys: lineKeys ?? this.lineKeys,
    categories: categories ?? this.categories,
    fields: fields ?? this.fields,
    parties: parties ?? this.parties,
    projects: projects ?? this.projects,
    errors: errors ?? this.errors,
    loadStatus: loadStatus ?? this.loadStatus,
    saveStatus: saveStatus ?? this.saveStatus,
    outcome: outcome == null ? this.outcome : outcome(),
    formRevision: formRevision ?? this.formRevision,
    receiptFilled: receiptFilled ?? this.receiptFilled,
  );

  @override
  List<Object?> get props => [
    businessId,
    currency,
    role,
    enabledFields,
    online,
    mode,
    draft,
    initialDraft,
    original,
    persisted,
    lineKeys,
    categories,
    fields,
    parties,
    projects,
    errors,
    loadStatus,
    saveStatus,
    outcome,
    formRevision,
    receiptFilled,
  ];
}
