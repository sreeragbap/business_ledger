import 'package:flutter/material.dart';

/// Built-in sections of the transaction form a business can switch on or
/// off (`settings.enabledStandardFields`). Keys are shared with
/// `STANDARD_FIELDS` in `functions/src/templates.ts`.
enum StandardField {
  lineItems(
    'lineItems',
    'Line items',
    'Quantity × rate rows instead of a single amount.',
    Icons.format_list_numbered_rounded,
  ),
  party(
    'party',
    'Customer / supplier',
    'Who the transaction is with.',
    Icons.person_outline_rounded,
  ),
  project(
    'project',
    'Project',
    'Tag entries to a job, site or engagement.',
    Icons.work_outline_rounded,
  ),
  paymentMethod(
    'paymentMethod',
    'Payment method',
    'Cash, bank transfer, card, UPI…',
    Icons.account_balance_wallet_outlined,
  ),
  dueDate(
    'dueDate',
    'Due date',
    'When an unpaid amount is due; drives overdue.',
    Icons.event_outlined,
  ),
  reference(
    'reference',
    'Reference',
    'An external number: PO, bill or cheque no.',
    Icons.tag_rounded,
  ),
  notes('notes', 'Notes', 'Free text for anything else.', Icons.notes_rounded),
  attachments(
    'attachments',
    'Attachments',
    'Photos and PDFs of bills and receipts.',
    Icons.attach_file_rounded,
  );

  const StandardField(this.key, this.label, this.description, this.icon);

  final String key;
  final String label;
  final String description;
  final IconData icon;

  /// `null` for a key this app version does not know.
  static StandardField? fromKey(Object? key) {
    for (final field in values) {
      if (field.key == key) return field;
    }
    return null;
  }
}
