import 'dart:async';

import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:flutter/material.dart';

/// A calendar-day picker that reads and writes `yyyy-MM-dd`.
class LedgerDateField extends StatelessWidget {
  const LedgerDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Choose a date',
    this.first,
    this.last,
    this.errorText,
    this.helperText,
    this.clearable = false,
    this.enabled = true,
    super.key,
  });

  final String label;

  /// `yyyy-MM-dd`, or `null` for none.
  final String? value;
  final ValueChanged<String?> onChanged;
  final String hint;

  /// Bounds as `yyyy-MM-dd`.
  final String? first;
  final String? last;
  final String? errorText;
  final String? helperText;
  final bool clearable;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = LedgerDates.parse(first) ?? DateTime(2000);
    final lastDate = LedgerDates.parse(last) ?? DateTime(now.year + 10);
    var initial =
        LedgerDates.parse(value) ?? DateTime(now.year, now.month, now.day);
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: label,
    );
    if (picked != null) onChanged(LedgerDates.key(picked));
  }

  @override
  Widget build(BuildContext context) {
    final text = LedgerDates.format(value);
    return Semantics(
      button: true,
      label: '$label: ${text.isEmpty ? 'not set' : text}',
      child: AppTextField(
        key: ValueKey('$label-$value'),
        label: label,
        hint: hint,
        initialValue: text,
        readOnly: true,
        enabled: enabled,
        prefixIcon: Icons.event_outlined,
        errorText: errorText,
        helperText: helperText,
        onTap: enabled ? () => unawaited(_pick(context)) : null,
        suffix: clearable && value != null && enabled
            ? IconButton(
                tooltip: 'Clear $label',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => onChanged(null),
              )
            : null,
      ),
    );
  }
}
