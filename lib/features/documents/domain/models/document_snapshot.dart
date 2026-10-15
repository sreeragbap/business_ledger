import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/features/documents/domain/models/json_reader.dart';
import 'package:equatable/equatable.dart';

/// What a document says, frozen when it was issued
/// (`functions/src/handlers/documents.ts`). A PDF is rendered from this and
/// nothing else, so a reprint years later shows what was sent.
class DocumentSnapshot extends Equatable {
  const DocumentSnapshot({
    required this.business,
    required this.transaction,
    this.party,
    this.settlement,
  });

  factory DocumentSnapshot.fromMap(Map<String, dynamic> map) =>
      DocumentSnapshot.read(JsonReader(map, 'snapshot'));

  factory DocumentSnapshot.read(JsonReader json) => DocumentSnapshot(
    business: DocumentBusiness.read(json.map('business')),
    party: switch (json.optionalMap('party')) {
      final party? => DocumentParty.read(party),
      null => null,
    },
    transaction: DocumentTransaction.read(json.map('transaction')),
    settlement: switch (json.optionalMap('settlement')) {
      final settlement? => DocumentSettlement.read(settlement),
      null => null,
    },
  );

  final DocumentBusiness business;
  final DocumentParty? party;
  final DocumentTransaction transaction;

  /// Present on receipts only.
  final DocumentSettlement? settlement;

  Currency get currency => business.currency;

  @override
  List<Object?> get props => [business, party, transaction, settlement];
}

class DocumentBusiness extends Equatable {
  const DocumentBusiness({
    required this.name,
    required this.currency,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxId = '',
  });

  factory DocumentBusiness.read(JsonReader json) {
    final currency = json.map('currency');
    return DocumentBusiness(
      name: json.string('name'),
      address: json.text('address'),
      phone: json.text('phone'),
      email: json.text('email'),
      taxId: json.text('taxId'),
      currency: Currency(
        code: currency.string('code'),
        decimals: currency.integer('decimals'),
        symbol: currency.string('symbol'),
      ),
    );
  }

  final String name;
  final String address;
  final String phone;
  final String email;
  final String taxId;
  final Currency currency;

  @override
  List<Object?> get props => [name, address, phone, email, taxId, currency];
}

class DocumentParty extends Equatable {
  const DocumentParty({
    required this.name,
    this.address = '',
    this.phone = '',
    this.email = '',
  });

  factory DocumentParty.read(JsonReader json) => DocumentParty(
    name: json.text('name'),
    address: json.text('address'),
    phone: json.text('phone'),
    email: json.text('email'),
  );

  final String name;
  final String address;
  final String phone;
  final String email;

  @override
  List<Object?> get props => [name, address, phone, email];
}

class DocumentLineItem extends Equatable {
  const DocumentLineItem({
    required this.description,
    required this.quantityMilli,
    required this.rateMinor,
    required this.amountMinor,
  });

  factory DocumentLineItem.read(JsonReader json) => DocumentLineItem(
    description: json.text('description'),
    quantityMilli: json.integer('quantityMilli'),
    rateMinor: json.integer('rateMinor'),
    amountMinor: json.integer('amountMinor'),
  );

  final String description;
  final int quantityMilli;
  final int rateMinor;
  final int amountMinor;

  @override
  List<Object?> get props => [
    description,
    quantityMilli,
    rateMinor,
    amountMinor,
  ];
}

class DocumentTransaction extends Equatable {
  const DocumentTransaction({
    required this.type,
    required this.direction,
    required this.date,
    required this.totalMinor,
    required this.paymentStatus,
    this.description = '',
    this.reference = '',
    this.dueDate,
    this.categoryName,
    this.projectName,
    this.paymentMethod = '',
    this.notes = '',
    this.lineItems = const [],
    this.creditedMinor = 0,
    this.paidMinor = 0,
    this.refundedMinor = 0,
    this.outstandingMinor = 0,
  });

  factory DocumentTransaction.read(JsonReader json) {
    final typeKey = json.string('type');
    final type = TransactionType.values.where((t) => t.key == typeKey);
    if (type.isEmpty) {
      throw FormatException('snapshot.transaction.type: unknown "$typeKey"');
    }
    final directionKey = json.string('direction');
    if (directionKey != Direction.inflow.key &&
        directionKey != Direction.outflow.key) {
      throw FormatException(
        'snapshot.transaction.direction: unknown "$directionKey"',
      );
    }
    final statusKey = json.string('paymentStatus');
    final status = PaymentStatus.values.where((s) => s.key == statusKey);
    if (status.isEmpty) {
      throw FormatException(
        'snapshot.transaction.paymentStatus: unknown "$statusKey"',
      );
    }
    return DocumentTransaction(
      type: type.first,
      direction: Direction.fromKey(directionKey),
      description: json.text('description'),
      reference: json.text('reference'),
      date: json.date('date'),
      dueDate: json.optionalDate('dueDate'),
      categoryName: json.optionalString('categoryName'),
      projectName: json.optionalString('projectName'),
      paymentMethod: json.text('paymentMethod'),
      notes: json.text('notes'),
      lineItems: json.mapList('lineItems').map(DocumentLineItem.read).toList(),
      totalMinor: json.integer('totalMinor'),
      creditedMinor: json.intOrZero('creditedMinor'),
      paidMinor: json.intOrZero('paidMinor'),
      refundedMinor: json.intOrZero('refundedMinor'),
      outstandingMinor: json.intOrZero('outstandingMinor'),
      paymentStatus: status.first,
    );
  }

  final TransactionType type;
  final Direction direction;
  final String description;
  final String reference;

  /// `yyyy-MM-dd`.
  final String date;
  final String? dueDate;
  final String? categoryName;
  final String? projectName;
  final String paymentMethod;
  final String notes;
  final List<DocumentLineItem> lineItems;
  final int totalMinor;
  final int creditedMinor;
  final int paidMinor;
  final int refundedMinor;
  final int outstandingMinor;
  final PaymentStatus paymentStatus;

  @override
  List<Object?> get props => [
    type,
    direction,
    description,
    reference,
    date,
    dueDate,
    categoryName,
    projectName,
    paymentMethod,
    notes,
    lineItems,
    totalMinor,
    creditedMinor,
    paidMinor,
    refundedMinor,
    outstandingMinor,
    paymentStatus,
  ];
}

/// The payment a receipt is for, with the balance as it stood right after
/// it. [paidToDateMinor] / [remainingMinor] are `null` for settlements
/// recorded before the server kept `balanceAfter`.
class DocumentSettlement extends Equatable {
  const DocumentSettlement({
    required this.amountMinor,
    required this.date,
    this.method = '',
    this.note = '',
    this.paidToDateMinor,
    this.remainingMinor,
  });

  factory DocumentSettlement.read(JsonReader json) => DocumentSettlement(
    amountMinor: json.integer('amountMinor'),
    date: json.date('date'),
    method: json.text('method'),
    note: json.text('note'),
    paidToDateMinor: json.optionalInt('paidToDateMinor'),
    remainingMinor: json.optionalInt('remainingMinor'),
  );

  final int amountMinor;
  final String date;
  final String method;
  final String note;
  final int? paidToDateMinor;
  final int? remainingMinor;

  @override
  List<Object?> get props => [
    amountMinor,
    date,
    method,
    note,
    paidToDateMinor,
    remainingMinor,
  ];
}
