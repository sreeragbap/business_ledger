import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/search_tokens.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/// The transaction form's working copy, and the one place a draft row is
/// shaped for the server.
///
/// [toRow] produces exactly what `app.valid_draft` and the row level
/// security of `transactions` accept (`supabase/README.md`): `status:
/// 'draft'`, a creatable `type`, `created_by` = the caller, no money the
/// server maintains (`paid_minor`…), no `confirmed_*` / `cancelled_*` /
/// link columns, `total_minor` an int within `0..1e13`, `description` ≤ 200
/// and ≤ 200 lines.
///
/// Name snapshots (`category_name`, `party_name`, `project_name`) are
/// written too: allowed, the list can show a draft's category without a
/// lookup, and they feed the draft's `search_tokens`. The server rewrites
/// all three on confirm.
class TransactionDraft extends Equatable {
  const TransactionDraft({
    required this.id,
    required this.type,
    required this.date,
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
    this.dueDate,
    this.useLineItems = false,
    this.lineItems = const [],
    this.totalMinor,
    this.customFields = const {},
  });

  /// A new, empty draft of [type] dated [date].
  factory TransactionDraft.blank({
    required String id,
    required TransactionType type,
    required String date,
  }) => TransactionDraft(
    id: id,
    type: type,
    date: date,
    direction: type.fixedDirection,
  );

  /// The form's copy of a stored entry. A missing date (an old, partial
  /// draft) becomes [fallbackDate].
  factory TransactionDraft.fromTransaction(
    LedgerTransaction tx, {
    required String fallbackDate,
  }) => TransactionDraft(
    id: tx.id,
    type: tx.type,
    direction: tx.effectiveDirection,
    date: LedgerDates.isValid(tx.date) ? tx.date! : fallbackDate,
    categoryId: tx.categoryId,
    categoryName: tx.categoryName,
    partyId: tx.partyId,
    partyName: tx.partyName,
    projectId: tx.projectId,
    projectName: tx.projectName,
    description: tx.description,
    reference: tx.reference,
    notes: tx.notes,
    paymentMethod: tx.paymentMethod,
    dueDate: LedgerDates.isValid(tx.dueDate) ? tx.dueDate : null,
    useLineItems: tx.lineItems.isNotEmpty,
    lineItems: tx.lineItems,
    totalMinor: tx.lineItems.isEmpty ? tx.totalMinor : null,
    customFields: tx.customFields,
  );

  static const int maxDescriptionLength = 200;
  static const int maxReferenceLength = 80;
  static const int maxNotesLength = 2000;
  static const int maxLineItems = 200;

  final String id;
  final TransactionType type;

  /// Chosen for payment/adjustment; equal to the fixed one otherwise.
  final Direction? direction;
  final String? categoryId;
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
  final String date;
  final String? dueDate;

  /// Quantity × rate rows instead of a single amount.
  final bool useLineItems;
  final List<LineItem> lineItems;

  /// The directly entered amount (when not itemised). `null` while empty.
  final int? totalMinor;
  final Map<String, dynamic> customFields;

  Direction? get resolvedDirection => type.fixedDirection ?? direction;

  /// The amount the entry is for, in minor units.
  int get total => useLineItems ? LineItem.total(lineItems) : (totalMinor ?? 0);

  List<String> get searchTokens => SearchTokens.of([
    description,
    reference,
    partyName,
    categoryName,
    projectName,
  ]);

  /// Custom values worth storing: blanks and nulls are dropped, so an
  /// untouched optional field is simply absent.
  Map<String, dynamic> get cleanedCustomFields => {
    for (final entry in customFields.entries)
      if (!isBlankValue(entry.value))
        entry.key: entry.value is String
            ? (entry.value as String).trim()
            : entry.value,
  };

  /// Mirrors `checkRequiredFields` on the server.
  static bool isBlankValue(Object? value) =>
      value == null ||
      (value is String && value.trim().isEmpty) ||
      (value is List && value.isEmpty);

  /// The draft as a camelCase map (the shape the models and RPCs use).
  ///
  /// [now] is any timestamp marker. Only a new draft gets `createdBy`,
  /// `createdAt` and `version`; an update keeps the stored ones. The
  /// server row is [toRow].
  Map<String, Object?> toMap({
    required String uid,
    required bool isNew,
    required Object now,
  }) => {
    'status': TransactionStatus.draft.key,
    'type': type.key,
    'direction': resolvedDirection?.key,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'partyId': partyId,
    'partyName': partyName,
    'projectId': projectId,
    'projectName': projectName,
    'description': description.trim(),
    'reference': reference.trim(),
    'notes': notes.trim(),
    'paymentMethod': paymentMethod.trim(),
    'date': date,
    'dueDate': dueDate,
    'lineItems': useLineItems
        ? [for (final line in lineItems) line.toMap()]
        : const <Map<String, Object>>[],
    'totalMinor': total,
    'customFields': cleanedCustomFields,
    'searchTokens': searchTokens,
    'updatedAt': now,
    if (isNew) ...{'createdBy': uid, 'createdAt': now, 'version': 0},
  };

  /// The `transactions` row a client writes (snake_case).
  ///
  /// A new draft ([isNew]) is a whole row, inserted (or re-sent) by upsert:
  /// with its `id`, `business_id`, `created_by` = [uid], `status` and
  /// `version` 0. An update is the editable columns only: `id`,
  /// `business_id` and `created_by` can never change (another editor may be
  /// saving someone else's draft).
  Map<String, Object?> toRow({
    required String uid,
    required String businessId,
    required bool isNew,
  }) => {
    if (isNew) ...{
      'id': id,
      'business_id': businessId,
      'created_by': uid,
      'version': 0,
    },
    'status': TransactionStatus.draft.key,
    'type': type.key,
    'direction': resolvedDirection?.key,
    'category_id': categoryId,
    'category_name': categoryName,
    'party_id': partyId,
    'party_name': partyName,
    'project_id': projectId,
    'project_name': projectName,
    'description': description.trim(),
    'reference': reference.trim(),
    'notes': notes.trim(),
    'payment_method': paymentMethod.trim(),
    'date': LedgerDates.isValid(date) ? date : null,
    'due_date': LedgerDates.isValid(dueDate) ? dueDate : null,
    'line_items': useLineItems
        ? [for (final line in lineItems) line.toMap()]
        : const <Map<String, Object>>[],
    'total_minor': total,
    'custom_fields': cleanedCustomFields,
    'search_tokens': searchTokens,
  };

  /// The `changes` for `editConfirmedTransaction`: only keys whose value
  /// differs from [original], as FUNCTIONS_API asks. Type and direction are
  /// fixed once confirmed and never sent.
  Map<String, Object?> changesFrom(LedgerTransaction original) {
    const equality = DeepCollectionEquality();
    final changes = <String, Object?>{};
    void put(String key, Object? value, Object? before) {
      if (!equality.equals(value, before)) changes[key] = value;
    }

    put('description', description.trim(), original.description);
    put('reference', reference.trim(), original.reference);
    put('notes', notes.trim(), original.notes);
    put('paymentMethod', paymentMethod.trim(), original.paymentMethod);
    put('date', date, original.date);
    put('dueDate', dueDate, original.dueDate);
    // The schema has no null category: a payment simply keeps none.
    if (categoryId != null) put('categoryId', categoryId, original.categoryId);
    put('partyId', partyId, original.partyId);
    put('projectId', projectId, original.projectId);
    final lines = useLineItems ? lineItems : const <LineItem>[];
    if (!equality.equals(lines, original.lineItems)) {
      changes['lineItems'] = [for (final line in lines) line.toMap()];
    }
    if (total != original.totalMinor) changes['totalMinor'] = total;
    put('customFields', cleanedCustomFields, original.customFields);
    return changes;
  }

  /// A copy as a new draft: same type, amounts, party and category, dated
  /// [date]. A due date that would fall
  /// before the new date is dropped.
  TransactionDraft duplicateAs({required String id, required String date}) =>
      TransactionDraft(
        id: id,
        type: type,
        direction: resolvedDirection,
        date: date,
        categoryId: categoryId,
        categoryName: categoryName,
        partyId: partyId,
        partyName: partyName,
        projectId: projectId,
        projectName: projectName,
        description: description,
        reference: reference,
        notes: notes,
        paymentMethod: paymentMethod,
        dueDate: dueDate != null && dueDate!.compareTo(date) >= 0
            ? dueDate
            : null,
        useLineItems: useLineItems,
        lineItems: lineItems,
        totalMinor: totalMinor,
        customFields: customFields,
      );

  /// Nullable fields take a getter so they can be cleared:
  /// `copyWith(dueDate: () => null)`.
  TransactionDraft copyWith({
    TransactionType? type,
    Direction? Function()? direction,
    String? Function()? categoryId,
    String? Function()? categoryName,
    String? Function()? partyId,
    String? Function()? partyName,
    String? Function()? projectId,
    String? Function()? projectName,
    String? description,
    String? reference,
    String? notes,
    String? paymentMethod,
    String? date,
    String? Function()? dueDate,
    bool? useLineItems,
    List<LineItem>? lineItems,
    int? Function()? totalMinor,
    Map<String, dynamic>? customFields,
  }) => TransactionDraft(
    id: id,
    type: type ?? this.type,
    direction: direction == null ? this.direction : direction(),
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    categoryName: categoryName == null ? this.categoryName : categoryName(),
    partyId: partyId == null ? this.partyId : partyId(),
    partyName: partyName == null ? this.partyName : partyName(),
    projectId: projectId == null ? this.projectId : projectId(),
    projectName: projectName == null ? this.projectName : projectName(),
    description: description ?? this.description,
    reference: reference ?? this.reference,
    notes: notes ?? this.notes,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    date: date ?? this.date,
    dueDate: dueDate == null ? this.dueDate : dueDate(),
    useLineItems: useLineItems ?? this.useLineItems,
    lineItems: lineItems ?? this.lineItems,
    totalMinor: totalMinor == null ? this.totalMinor : totalMinor(),
    customFields: customFields ?? this.customFields,
  );

  @override
  List<Object?> get props => [
    id,
    type,
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
    useLineItems,
    lineItems,
    totalMinor,
    customFields,
  ];
}
