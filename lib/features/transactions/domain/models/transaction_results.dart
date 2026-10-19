import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:equatable/equatable.dart';

/// What `confirmTransaction` returns.
class ConfirmResult extends Equatable {
  const ConfirmResult({
    required this.transactionId,
    required this.version,
    this.paymentStatus,
    this.settlementId,
  });

  factory ConfirmResult.fromMap(Map<String, dynamic> map) => ConfirmResult(
    transactionId: map.readString('transactionId'),
    version: map.readInt('version'),
    paymentStatus: _status(map),
    settlementId: map.readOptionalString('settlementId'),
  );

  final String transactionId;
  final int version;
  final PaymentStatus? paymentStatus;

  /// Set when the confirm also settled the full amount.
  final String? settlementId;

  @override
  List<Object?> get props => [
    transactionId,
    version,
    paymentStatus,
    settlementId,
  ];
}

/// What `editConfirmedTransaction` and `cancelTransaction` return.
class MutationResult extends Equatable {
  const MutationResult({
    required this.transactionId,
    required this.version,
    this.paymentStatus,
    this.voidedDocuments = 0,
  });

  factory MutationResult.fromMap(Map<String, dynamic> map) => MutationResult(
    transactionId: map.readString('transactionId'),
    version: map.readInt('version'),
    paymentStatus: _status(map),
    voidedDocuments: map.readInt('voidedDocuments'),
  );

  final String transactionId;
  final int version;
  final PaymentStatus? paymentStatus;

  /// Cancel only: how many issued documents were marked void.
  final int voidedDocuments;

  @override
  List<Object?> get props => [
    transactionId,
    version,
    paymentStatus,
    voidedDocuments,
  ];
}

/// What `recordSettlement` returns.
class SettlementResult extends Equatable {
  const SettlementResult({
    required this.settlementId,
    required this.transactionId,
    required this.version,
    this.linkedTransactionId,
    this.paymentStatus,
    this.outstandingMinor = 0,
  });

  factory SettlementResult.fromMap(Map<String, dynamic> map) =>
      SettlementResult(
        settlementId: map.readString('settlementId'),
        transactionId: map.readString('transactionId'),
        version: map.readInt('version'),
        linkedTransactionId: map.readOptionalString('linkedTransactionId'),
        paymentStatus: _status(map),
        outstandingMinor: map.readInt('outstandingMinor'),
      );

  final String settlementId;
  final String transactionId;
  final int version;

  /// The refund entry created alongside a refund.
  final String? linkedTransactionId;
  final PaymentStatus? paymentStatus;
  final int outstandingMinor;

  @override
  List<Object?> get props => [
    settlementId,
    transactionId,
    version,
    linkedTransactionId,
    paymentStatus,
    outstandingMinor,
  ];
}

PaymentStatus? _status(Map<String, dynamic> map) {
  final key = map.readOptionalString('paymentStatus');
  return key == null ? null : PaymentStatus.fromKey(key);
}
