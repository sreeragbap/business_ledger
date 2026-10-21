import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_money_field.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/categories/domain/const/field_type.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/widgets/ledger_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The creatable types as chips, with what each one means.
class TransactionTypePicker extends StatelessWidget {
  const TransactionTypePicker({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  final bool enabled;

  static const List<TransactionType> creatable = [
    TransactionType.sale,
    TransactionType.income,
    TransactionType.purchase,
    TransactionType.expense,
    TransactionType.payment,
    TransactionType.adjustment,
  ];

  static IconData iconOf(TransactionType type) => switch (type) {
    TransactionType.sale => Icons.sell_outlined,
    TransactionType.income => Icons.savings_outlined,
    TransactionType.purchase => Icons.shopping_bag_outlined,
    TransactionType.expense => Icons.receipt_long_outlined,
    TransactionType.payment => Icons.swap_horiz_rounded,
    TransactionType.adjustment => Icons.tune_rounded,
    TransactionType.refund => Icons.undo_rounded,
  };

  static String describe(TransactionType type) => switch (type) {
    TransactionType.sale => 'Goods or services sold; can be paid later.',
    TransactionType.income => 'Money earned: fees, interest, other income.',
    TransactionType.purchase => 'Stock or goods bought; can be paid later.',
    TransactionType.expense => 'Running costs: rent, wages, utilities.',
    TransactionType.payment =>
      'Cash only: an advance, a transfer, a loan. Settled on confirm.',
    TransactionType.adjustment =>
      'Corrects income or expense, with no cash side.',
    TransactionType.refund => 'Created from a refund on the original.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm.w,
          runSpacing: AppSpacing.sm.h,
          children: [
            for (final type in creatable)
              ChoiceChip(
                avatar: Icon(
                  iconOf(type),
                  size: 18.r,
                  color: type == selected
                      ? context.colors.accent
                      : context.colors.textSecondary,
                ),
                label: Text(type.label),
                selected: type == selected,
                showCheckmark: false,
                onSelected: enabled ? (_) => onChanged(type) : null,
              ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        AnimatedSwitcher(
          duration: AppMotion.fast,
          child: Text(
            describe(selected),
            key: ValueKey(selected),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// A read-only field that opens a picker: category, party, project.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.onTap,
    this.value,
    this.hint = 'Choose',
    this.icon,
    this.errorText,
    this.onClear,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? value;
  final String hint;
  final IconData? icon;
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: ${value ?? 'not set'}',
    child: AppTextField(
      key: ValueKey('$label-$value'),
      label: label,
      hint: hint,
      initialValue: value ?? '',
      readOnly: true,
      enabled: enabled,
      prefixIcon: icon,
      errorText: errorText,
      onTap: enabled ? onTap : null,
      suffix: value != null && onClear != null && enabled
          ? IconButton(
              tooltip: 'Clear $label',
              icon: const Icon(Icons.close_rounded),
              onPressed: onClear,
            )
          : const Icon(Icons.expand_more_rounded),
    ),
  );
}

/// Quantity × rate rows. Each line's amount is `Money.lineAmount`, rounded
/// per line; the total is their sum (shown by the caller).
class LineItemsEditor extends StatelessWidget {
  const LineItemsEditor({
    required this.lines,
    required this.keys,
    required this.currency,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
    this.errorText,
    super.key,
  });

  final List<LineItem> lines;

  /// Stable per row, so removing one keeps the others' text.
  final List<int> keys;
  final Currency currency;
  final void Function(
    int index, {
    String? description,
    int? quantityMilli,
    int? rateMinor,
  })
  onChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          AnimatedSize(
            key: ValueKey('line-${i < keys.length ? keys[i] : i}'),
            duration: AppMotion.medium,
            child: _LineRow(
              index: i,
              line: lines[i],
              currency: currency,
              enabled: enabled,
              onChanged: onChanged,
              onRemove: lines.length > 1 ? () => onRemove(i) : null,
            ),
          ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
            child: Text(
              errorText!,
              style: textTheme.bodySmall?.copyWith(color: context.colors.error),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add line'),
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.index,
    required this.line,
    required this.currency,
    required this.enabled,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final LineItem line;
  final Currency currency;
  final bool enabled;
  final void Function(
    int index, {
    String? description,
    int? quantityMilli,
    int? rateMinor,
  })
  onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm.h),
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  hint: 'Item ${index + 1}',
                  initialValue: line.description,
                  enabled: enabled,
                  maxLength: LineItem.maxDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => onChanged(index, description: value),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove line ${index + 1}',
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: enabled ? onRemove : null,
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84.w,
                child: AppTextField(
                  label: 'Qty',
                  initialValue: Money.quantity(line.quantityMilli),
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                  ],
                  style: AppTextStyles.tabular(textTheme.bodyLarge!),
                  onChanged: (value) => onChanged(
                    index,
                    quantityMilli: Money.parseQuantityMilli(value) ?? 0,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 40.h,
                  left: AppSpacing.sm.w,
                  right: AppSpacing.sm.w,
                ),
                child: Text('×', style: textTheme.titleMedium),
              ),
              Expanded(
                child: AppMoneyField(
                  label: 'Rate',
                  currency: currency,
                  initialMinor: line.rateMinor == 0 ? null : line.rateMinor,
                  enabled: enabled,
                  allowZero: true,
                  isRequired: false,
                  onChanged: (minor) => onChanged(index, rateMinor: minor ?? 0),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          Row(
            children: [
              Text('Amount', style: textTheme.bodySmall),
              const Spacer(),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Text(
                  Money.format(line.amountMinor, currency),
                  key: ValueKey(line.amountMinor),
                  style: AppTextStyles.tabular(textTheme.titleSmall!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One business-defined field, in the input its type calls for. Values are
/// stored as `FieldType` documents: text → String, number → num, date →
/// `yyyy-MM-dd`, select → one of the options, checkbox → bool.
class CustomFieldInput extends StatelessWidget {
  const CustomFieldInput({
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  final CustomField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;
  final String? errorText;
  final bool enabled;

  String get _label => field.required ? '${field.label} *' : field.label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    switch (field.type) {
      case FieldType.text:
        return AppTextField(
          label: _label,
          initialValue: value is String ? value! as String : '',
          enabled: enabled,
          errorText: errorText,
          maxLength: 500,
          onChanged: onChanged,
        );
      case FieldType.number:
        return AppTextField(
          label: _label,
          initialValue: value is num ? '$value' : '',
          enabled: enabled,
          errorText: errorText,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          onChanged: (text) => onChanged(num.tryParse(text.trim())),
        );
      case FieldType.date:
        return LedgerDateField(
          label: _label,
          value: value is String ? value! as String : null,
          enabled: enabled,
          errorText: errorText,
          clearable: true,
          onChanged: onChanged,
        );
      case FieldType.select:
        final options = field.options;
        final current = value is String && options.contains(value)
            ? value! as String
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_label, style: textTheme.labelMedium),
            SizedBox(height: AppSpacing.sm.h),
            Wrap(
              spacing: AppSpacing.sm.w,
              runSpacing: AppSpacing.xs.h,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text(option),
                    selected: option == current,
                    onSelected: enabled
                        ? (selected) => onChanged(selected ? option : null)
                        : null,
                  ),
              ],
            ),
            if (errorText != null)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs.h),
                child: Text(
                  errorText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
          ],
        );
      case FieldType.checkbox:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_label),
          subtitle: errorText == null
              ? null
              : Text(
                  errorText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
          value: value == true,
          onChanged: enabled ? onChanged : null,
        );
    }
  }
}
