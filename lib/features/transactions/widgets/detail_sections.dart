import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/features/categories/domain/const/field_type.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/transactions/domain/models/audit_entry.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/line_item.dart';
import 'package:business_ledger/features/transactions/domain/models/settlement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Where the money stands: total, credits, cash in/out, refunds,
/// outstanding and the recognised amount — with cash and recognised figures
/// labelled apart (ARCHITECTURE §6).
class BalanceBreakdown extends StatelessWidget {
  const BalanceBreakdown({
    required this.transaction,
    required this.currency,
    super.key,
  });

  final LedgerTransaction transaction;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final balance = tx.balance;
    final inflow = tx.isInflow;
    final textTheme = Theme.of(context).textTheme;
    final settled = balance.paid + balance.credited;
    final progress = balance.total <= 0
        ? 0.0
        : (settled / balance.total).clamp(0.0, 1.0);
    final recognisedLabel = tx.type == TransactionType.payment
        ? 'Recognised (cash only, not income or expense)'
        : inflow
        ? 'Recognised income'
        : 'Recognised expense';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FigureRow(
            label: 'Total',
            minor: balance.total,
            currency: currency,
            strong: true,
          ),
          if (balance.credited > 0)
            _FigureRow(
              label: 'Credits & discounts',
              minor: -balance.credited,
              currency: currency,
            ),
          if (tx.isSettleable) ...[
            _FigureRow(
              label: inflow ? 'Cash received' : 'Cash paid',
              minor: balance.paid,
              currency: currency,
              caption: 'cash',
            ),
            if (balance.refunded > 0)
              _FigureRow(
                label: inflow ? 'Refunded to them' : 'Refunded to you',
                minor: balance.refunded,
                currency: currency,
                caption: 'cash',
                colour: AppColors.refund,
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
              child: Semantics(
                label: '${(progress * 100).round()} percent settled',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceHigh,
                      color: inflow ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              ),
            ),
            _FigureRow(
              label: inflow
                  ? 'Outstanding — still to receive'
                  : 'Outstanding — still to pay',
              minor: tx.isCancelled ? 0 : balance.outstanding,
              currency: currency,
              strong: true,
              colour: balance.outstanding > 0 && tx.isConfirmed
                  ? AppColors.warning
                  : null,
            ),
          ],
          const Divider(height: 24),
          _FigureRow(
            label: recognisedLabel,
            minor: tx.isCancelled ? 0 : balance.effective,
            currency: currency,
            caption: 'effective',
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            tx.isCancelled
                ? 'Cancelled: none of these count any more.'
                : tx.isDraft
                ? 'A draft counts nowhere until it is confirmed.'
                : 'Cash is money that actually moved. Recognised is what '
                      'counts in income and expense reports.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({
    required this.label,
    required this.minor,
    required this.currency,
    this.caption,
    this.strong = false,
    this.colour,
  });

  final String label;
  final int minor;
  final Currency currency;
  final String? caption;
  final bool strong;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = Money.format(minor, currency);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  style: strong ? textTheme.titleSmall : textTheme.bodyMedium,
                  children: [
                    if (caption != null)
                      TextSpan(
                        text: '  $caption',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Text(
              value,
              style:
                  AppTextStyles.tabular(
                    strong ? textTheme.titleSmall! : textTheme.bodyMedium!,
                  ).copyWith(
                    color: colour ?? (strong ? AppColors.textPrimary : null),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label/value line in the details card.
class DetailLine extends StatelessWidget {
  const DetailLine({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18.r, color: AppColors.textTertiary),
            SizedBox(width: AppSpacing.sm.w),
          ],
          SizedBox(
            width: 112.w,
            child: Text(label, style: textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// A stored custom value, as text.
String customFieldText(CustomField? field, Object? value) {
  if (value == null) return '—';
  return switch (field?.type) {
    FieldType.checkbox => value == true ? 'Yes' : 'No',
    FieldType.date when value is String => LedgerDates.format(value),
    _ => '$value',
  };
}

/// The line items, with quantity × rate and each rounded line amount.
class LineItemsTable extends StatelessWidget {
  const LineItemsTable({
    required this.lines,
    required this.currency,
    super.key,
  });

  final List<LineItem> lines;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final figure = AppTextStyles.tabular(textTheme.bodyMedium!);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, line) in lines.indexed) ...[
            if (index > 0) const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.description.isEmpty
                            ? 'Line ${index + 1}'
                            : line.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${Money.quantity(line.quantityMilli)} × '
                        '${Money.format(line.rateMinor, currency)}',
                        style: AppTextStyles.tabular(textTheme.bodySmall!),
                      ),
                    ],
                  ),
                ),
                Text(Money.format(line.amountMinor, currency), style: figure),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Payments, refunds and credits as a timeline, newest first.
class SettlementTimeline extends StatelessWidget {
  const SettlementTimeline({
    required this.settlements,
    required this.currency,
    this.onOpenLinked,
    super.key,
  });

  final List<Settlement> settlements;
  final Currency currency;

  /// Opens a refund's visible ledger entry.
  final ValueChanged<String>? onOpenLinked;

  static Color colourOf(SettlementKind kind) => switch (kind) {
    SettlementKind.payment => AppColors.income,
    SettlementKind.refund => AppColors.refund,
    SettlementKind.credit => AppColors.info,
  };

  static IconData iconOf(SettlementKind kind) => switch (kind) {
    SettlementKind.payment => Icons.payments_outlined,
    SettlementKind.refund => Icons.undo_rounded,
    SettlementKind.credit => Icons.local_offer_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (index, settlement) in settlements.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36.r,
                  child: Column(
                    children: [
                      Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: AppColors.tint(colourOf(settlement.kind)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconOf(settlement.kind),
                          size: 16.r,
                          color: colourOf(settlement.kind),
                        ),
                      ),
                      if (index < settlements.length - 1)
                        const Expanded(
                          child: VerticalDivider(
                            width: 2,
                            thickness: 2,
                            color: AppColors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                settlement.kind.label,
                                style: textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              Money.format(settlement.amountMinor, currency),
                              style: AppTextStyles.tabular(
                                textTheme.titleSmall!,
                              ).copyWith(color: colourOf(settlement.kind)),
                            ),
                          ],
                        ),
                        Text(
                          [
                            LedgerDates.format(settlement.date),
                            if (settlement.method.isNotEmpty) settlement.method,
                            if (settlement.voided) 'Void',
                          ].join(' · '),
                          style: textTheme.bodySmall,
                        ),
                        if (settlement.note.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xxs.h),
                            child: Text(
                              settlement.note,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        if (settlement.outstandingAfter != null)
                          Text(
                            'Outstanding after: ${Money.format(
                              settlement.outstandingAfter!,
                              currency,
                            )}',
                            style: AppTextStyles.tabular(
                              textTheme.bodySmall!,
                            ),
                          ),
                        if (settlement.linkedTransactionId != null &&
                            onOpenLinked != null)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () =>
                                onOpenLinked!(settlement.linkedTransactionId!),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('View refund entry'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The audit trail (admins only).
class AuditHistory extends StatelessWidget {
  const AuditHistory({required this.entries, super.key});

  final List<AuditEntry> entries;

  static final DateFormat _at = DateFormat('d MMM yyyy, HH:mm', 'en_US');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (entries.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.sm.r),
        child: Text('No history yet.', style: textTheme.bodySmall),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18.r,
                  color: AppColors.textTertiary,
                ),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.label, style: textTheme.bodyMedium),
                      Text(
                        [
                          if (entry.at != null) _at.format(entry.at!),
                          if (entry.changedKeys.isNotEmpty &&
                              entry.action == 'edit')
                            'changed ${entry.changedKeys.join(', ')}',
                          if (entry.note.isNotEmpty) entry.note,
                        ].join(' · '),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
