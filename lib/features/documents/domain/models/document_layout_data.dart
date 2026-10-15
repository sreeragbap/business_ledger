import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/features/documents/domain/models/document_snapshot.dart';
import 'package:business_ledger/features/documents/domain/models/issued_document.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// A label / value pair in a totals or details block.
class LayoutRow extends Equatable {
  const LayoutRow(this.label, this.value, {this.emphasis = false});

  final String label;
  final String value;

  /// Drawn larger and bold: the figure the reader is looking for.
  final bool emphasis;

  @override
  List<Object?> get props => [label, value, emphasis];

  @override
  String toString() => '$label: $value${emphasis ? ' (!)' : ''}';
}

class LayoutLine extends Equatable {
  const LayoutLine({
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  final String description;
  final String quantity;
  final String rate;
  final String amount;

  @override
  List<Object?> get props => [description, quantity, rate, amount];
}

/// Every string a document PDF shows, computed from the snapshot.
///
/// The PDF builder only draws this, so the numbers on the page are tested
/// here as plain strings, with no PDF parsing. All money goes through
/// `Money.format` on integer minor units.
class DocumentLayoutData extends Equatable {
  const DocumentLayoutData({
    required this.title,
    required this.number,
    required this.businessName,
    required this.businessLines,
    required this.partyHeading,
    required this.partyLines,
    required this.details,
    required this.lines,
    required this.totals,
    required this.receipt,
    required this.notes,
    required this.voided,
    required this.footer,
  });

  /// Builds the layout for [document].
  ///
  /// [canRender] says whether the PDF font can draw a piece of text; when it
  /// cannot draw the currency symbol (₹ in the built-in Helvetica) amounts
  /// are prefixed with the ISO code instead: `INR 1,250.00`.
  factory DocumentLayoutData.from(
    IssuedDocument document, {
    bool Function(String text)? canRender,
    DateTime? today,
  }) {
    final snapshot = document.snapshot;
    final tx = snapshot.transaction;
    final currency = printableCurrency(
      snapshot.currency,
      canRender: canRender ?? (_) => true,
    );
    String money(int minor) => Money.format(minor, currency);

    final isReceipt = document.type == DocumentType.receipt;
    final settlement = snapshot.settlement;
    final inflow = tx.direction == Direction.inflow;

    final details = <LayoutRow>[
      LayoutRow('${document.type.label} no.', document.number),
      LayoutRow(
        'Issue date',
        formatDate(document.issuedAt ?? today ?? DateTime.now()),
      ),
      if (isReceipt && settlement != null)
        LayoutRow('Payment date', formatDay(settlement.date))
      else
        LayoutRow('Date', formatDay(tx.date)),
      if (!isReceipt && tx.dueDate != null)
        LayoutRow('Due date', formatDay(tx.dueDate!)),
      if (tx.reference.isNotEmpty) LayoutRow('Reference', tx.reference),
      if (tx.projectName?.isNotEmpty ?? false)
        LayoutRow('Project', tx.projectName!),
    ];

    final lines = tx.lineItems.isEmpty
        ? [
            LayoutLine(
              description: _describe(tx),
              quantity: '1',
              rate: money(tx.totalMinor),
              amount: money(tx.totalMinor),
            ),
          ]
        : [
            for (final item in tx.lineItems)
              LayoutLine(
                description: item.description.isEmpty
                    ? _describe(tx)
                    : item.description,
                quantity: Money.quantity(item.quantityMilli),
                rate: money(item.rateMinor),
                amount: money(item.amountMinor),
              ),
          ];

    final payable = tx.totalMinor - tx.creditedMinor;
    final totals = <LayoutRow>[
      LayoutRow('Subtotal', money(tx.totalMinor)),
      if (tx.creditedMinor > 0)
        LayoutRow('Credits / discounts', money(-tx.creditedMinor)),
      LayoutRow('Total', money(payable), emphasis: isReceipt),
      if (!isReceipt) ...[
        LayoutRow(inflow ? 'Paid' : 'Paid to supplier', money(tx.paidMinor)),
        if (tx.refundedMinor > 0)
          LayoutRow('Refunded', money(tx.refundedMinor)),
        LayoutRow('Balance due', money(tx.outstandingMinor), emphasis: true),
      ],
    ];

    final receipt = !isReceipt || settlement == null
        ? const <LayoutRow>[]
        : [
            LayoutRow(
              inflow ? 'Amount received' : 'Amount paid',
              money(settlement.amountMinor),
              emphasis: true,
            ),
            LayoutRow('Payment date', formatDay(settlement.date)),
            LayoutRow(
              'Method',
              settlement.method.isEmpty ? 'Not specified' : settlement.method,
            ),
            if (settlement.paidToDateMinor != null)
              LayoutRow('Paid to date', money(settlement.paidToDateMinor!)),
            if (settlement.remainingMinor != null)
              LayoutRow(
                'Remaining balance',
                money(settlement.remainingMinor!),
              ),
          ];

    final notes = [
      if (settlement != null && settlement.note.isNotEmpty) settlement.note,
      if (tx.notes.isNotEmpty) tx.notes,
    ].join('\n\n');

    final business = snapshot.business;
    final party = snapshot.party;

    return DocumentLayoutData(
      title: document.type.label.toUpperCase(),
      number: document.number,
      businessName: business.name,
      businessLines: [
        ..._nonEmpty([business.address]),
        ..._nonEmpty([business.phone, business.email]),
        if (business.taxId.isNotEmpty) 'Tax ID: ${business.taxId}',
      ],
      partyHeading: switch (document.type) {
        DocumentType.invoice => 'Bill to',
        DocumentType.bill => 'From',
        DocumentType.receipt => inflow ? 'Received from' : 'Paid to',
      },
      partyLines: party == null
          ? const []
          : _nonEmpty([party.name, party.address, party.phone, party.email]),
      details: details,
      lines: lines,
      totals: totals,
      receipt: receipt,
      notes: notes,
      voided: document.voided,
      footer: isReceipt
          ? 'This receipt confirms the payment above.'
          : inflow
          ? 'Thank you for your business.'
          : 'Recorded by ${business.name}.',
    );
  }

  /// [currency] with its symbol when the font can draw it, else with the
  /// ISO code (`INR `) in its place.
  static Currency printableCurrency(
    Currency currency, {
    required bool Function(String text) canRender,
  }) {
    final symbol = currency.symbol;
    if (symbol.trim().isNotEmpty && canRender(symbol)) return currency;
    return Currency(
      code: currency.code,
      decimals: currency.decimals,
      symbol: '${currency.code} ',
    );
  }

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy', 'en_US');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// `2026-10-14` → `14 Oct 2026`. A calendar day, so no time zone applies.
  static String formatDay(String day) {
    final parsed = DateTime.tryParse(day);
    return parsed == null ? day : _dateFormat.format(parsed);
  }

  static String _describe(DocumentTransaction tx) {
    if (tx.description.isNotEmpty) return tx.description;
    if (tx.categoryName?.isNotEmpty ?? false) return tx.categoryName!;
    return tx.type.label;
  }

  static List<String> _nonEmpty(List<String> values) => [
    for (final value in values)
      if (value.trim().isNotEmpty) value.trim(),
  ];

  /// INVOICE / BILL / RECEIPT.
  final String title;
  final String number;
  final String businessName;

  /// Address, phone, email, tax id: only those that are set.
  final List<String> businessLines;
  final String partyHeading;

  /// Empty when the transaction has no party.
  final List<String> partyLines;

  /// Number, dates, reference.
  final List<LayoutRow> details;
  final List<LayoutLine> lines;
  final List<LayoutRow> totals;

  /// Receipts only: amount, date, method, paid to date, remaining.
  final List<LayoutRow> receipt;
  final String notes;
  final bool voided;
  final String footer;

  bool get isReceipt => receipt.isNotEmpty;

  /// Every string on the page, for font coverage checks.
  Iterable<String> get allText sync* {
    yield title;
    yield number;
    yield businessName;
    yield* businessLines;
    yield partyHeading;
    yield* partyLines;
    for (final row in [...details, ...totals, ...receipt]) {
      yield row.label;
      yield row.value;
    }
    for (final line in lines) {
      yield line.description;
      yield line.quantity;
      yield line.rate;
      yield line.amount;
    }
    yield notes;
    yield footer;
  }

  @override
  List<Object?> get props => [
    title,
    number,
    businessName,
    businessLines,
    partyHeading,
    partyLines,
    details,
    lines,
    totals,
    receipt,
    notes,
    voided,
    footer,
  ];
}
