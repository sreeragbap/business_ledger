part of 'settlement_form_cubit.dart';

class SettlementFormState extends Equatable {
  const SettlementFormState({
    this.businessId,
    this.transaction,
    this.kind = SettlementKind.payment,
    this.amountMinor,
    this.date = '',
    this.today = '',
    this.method = '',
    this.note = '',
    this.errors = const {},
    this.submitStatus = const Status.initial(),
    this.result,
  });

  final String? businessId;

  /// Live: refreshed while the sheet is open.
  final LedgerTransaction? transaction;
  final SettlementKind kind;
  final int? amountMinor;

  /// When the money moved (`yyyy-MM-dd`), separate from the transaction
  /// date. Defaults to today.
  final String date;
  final String today;
  final String method;
  final String note;
  final Map<String, String> errors;
  final Status submitStatus;
  final SettlementResult? result;

  /// Why [kind] cannot be recorded, or `null`.
  String? unavailableReason(SettlementKind kind) =>
      transaction?.settlementUnavailableReason(kind) ?? _loading(kind);

  String? _loading(SettlementKind kind) =>
      transaction == null ? 'Still loading.' : null;

  /// The most the selected kind can be.
  int get maxAmount => transaction?.maxSettlement(kind) ?? 0;

  /// The live check of what is typed; `null` while empty or valid.
  LedgerViolation? get violation {
    final tx = transaction;
    final amount = amountMinor;
    if (tx == null || amount == null) return null;
    return tx.checkSettlement(kind, amount);
  }

  /// The balance after this settlement, when it would be accepted.
  Balance? get preview {
    final tx = transaction;
    final amount = amountMinor;
    if (tx == null || amount == null || violation != null) return null;
    return tx.previewSettlement(kind, amount);
  }

  PaymentStatus? get previewStatus {
    final next = preview;
    final tx = transaction;
    if (next == null || tx == null) return null;
    return tx.paymentStatusFor(next);
  }

  bool get canSubmit =>
      unavailableReason(kind) == null &&
      amountMinor != null &&
      violation == null &&
      !submitStatus.isLoading;

  SettlementFormState copyWith({
    LedgerTransaction? transaction,
    SettlementKind? kind,
    int? Function()? amountMinor,
    String? date,
    String? method,
    String? note,
    Map<String, String>? errors,
    Status? submitStatus,
    SettlementResult? result,
  }) => SettlementFormState(
    businessId: businessId,
    transaction: transaction ?? this.transaction,
    kind: kind ?? this.kind,
    amountMinor: amountMinor == null ? this.amountMinor : amountMinor(),
    date: date ?? this.date,
    today: today,
    method: method ?? this.method,
    note: note ?? this.note,
    errors: errors ?? this.errors,
    submitStatus: submitStatus ?? this.submitStatus,
    result: result ?? this.result,
  );

  @override
  List<Object?> get props => [
    businessId,
    transaction,
    kind,
    amountMinor,
    date,
    today,
    method,
    note,
    errors,
    submitStatus,
    result,
  ];
}
