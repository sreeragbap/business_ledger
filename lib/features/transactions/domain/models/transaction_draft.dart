import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/search_tokens.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

/// The transaction form's working copy, and the one place a draft document
/// is shaped for Firestore.
///
/// [toMap] produces exactly what `validDraft` in `firestore.rules` accepts
/// (FUNCTIONS_API "Draft shape"): `status: 'draft'`, a creatable `type`,
/// `createdBy`, no money the functions maintain (`paidMinor`…), no
/// `confirmed*` / `cancelled*` / link fields, `totalMinor` an int within
/// `0..1e13`, `description` ≤ 200, ≤ 200 lines and ≤ 20 attachments.
///
/// Name snapshots (`categoryName`, `partyName`, `projectName`) are written
/// too: the rules allow them, the list can show a draft's category without a
/// lookup, and they feed the draft's `searchTokens`. The server rewrites all
/// three on confirm.
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
    this.attachments = const [],
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
    attachments: tx.attachments,
  );

  static const int maxDescriptionLength = 200;
  static const int maxReferenceLength = 80;
  static const int maxNotesLength = 2000;
  static const int maxLineItems = 200;
  static const int maxAttachments = 20;

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
  final List<String> attachments;

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

  /// The Firestore document for a draft.
  ///
  /// [now] is the server-timestamp sentinel (`FieldValue.serverTimestamp()`
  /// from the service, any marker in tests). Only a new draft gets
  /// `createdBy`, `createdAt` and `version`; an update keeps the stored ones.
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
    if (LedgerDates.isValid(date)) 'dateTs': LedgerDates.timestamp(date),
    'dueDate': dueDate,
    'lineItems': useLineItems
        ? [for (final line in lineItems) line.toMap()]
        : const <Map<String, Object>>[],
    'totalMinor': total,
    'customFields': cleanedCustomFields,
    'attachments': attachments,
    'searchTokens': searchTokens,
    'updatedAt': now,
    if (isNew) ...{'createdBy': uid, 'createdAt': now, 'version': 0},
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
    put('attachments', attachments, original.attachments);
    return changes;
  }

  /// A copy as a new draft: same type, amounts, party and category, dated
  /// [date]. Attachments stay with the original; a due date that would fall
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
    List<String>? attachments,
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
    attachments: attachments ?? this.attachments,
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
    attachments,
  ];
}
