import 'dart:async';

import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/sync/action_outcome.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_bottom_sheet.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_money_field.dart';
import 'package:business_ledger/core/widgets/app_status_chip.dart';
import 'package:business_ledger/core/widgets/app_text_field.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_results.dart';
import 'package:business_ledger/features/transactions/logic/settlement_form_cubit/settlement_form_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/ledger_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opens the settlement sheet over [cubit] (already started). Resolves the
/// outcome once recorded (applied, or queued when [online] is false),
/// `null` when dismissed.
Future<ActionOutcome<SettlementResult>?> showSettlementSheet({
  required BuildContext context,
  required SettlementFormCubit cubit,
  required Currency currency,
  bool online = true,
}) => showAppBottomSheet<ActionOutcome<SettlementResult>>(
  context: context,
  title: 'Record money',
  child: BlocProvider.value(
    value: cubit,
    child: SettlementSheet(currency: currency, online: online),
  ),
);

/// Kind, amount (with quick fill), the date the money moved, method and
/// note, and a live preview of the balance afterwards. Kinds that cannot
/// apply are disabled with the reason.
class SettlementSheet extends StatefulWidget {
  const SettlementSheet({
    required this.currency,
    this.online = true,
    super.key,
  });

  final Currency currency;

  /// The cloud is reachable. When not, the settlement is queued.
  final bool online;

  static const String queuedNote =
      'Not syncing right now: this is kept on this device and recorded when '
      'synced. It may be refused if the balance changed meanwhile.';

  static String describe(SettlementKind kind, LedgerTransaction tx) =>
      switch (kind) {
        SettlementKind.payment =>
          tx.isInflow
              ? 'Money received against this entry.'
              : 'Money paid against this entry.',
        SettlementKind.refund =>
          'Money handed back. Lowers the recognised amount; it does not '
              'reopen the balance.',
        SettlementKind.credit =>
          'A discount or credit note: lowers what is owed, no cash moves.',
      };

  @override
  State<SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends State<SettlementSheet> {
  /// Bumped when the amount is filled from outside the field, so the field
  /// is rebuilt with the new value.
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettlementFormCubit>();
    final currency = widget.currency;
    return BlocConsumer<SettlementFormCubit, SettlementFormState>(
      listenWhen: (p, c) =>
          p.submitStatus != c.submitStatus && c.submitStatus.isSuccess,
      listener: (context, state) => Navigator.of(context).pop(state.outcome),
      builder: (context, state) {
        final tx = state.transaction;
        if (tx == null) return const SizedBox.shrink();
        final textTheme = Theme.of(context).textTheme;
        final kind = state.kind;
        final unavailable = state.unavailableReason(kind);
        final reasons = [
          for (final other in SettlementKind.values)
            if (state.unavailableReason(other) case final reason?)
              '${other.label}: $reason',
        ];
        final fullLabel = kind == SettlementKind.refund
            ? 'Full refundable'
            : 'Full outstanding';
        final amountError =
            state.errors['amountMinor'] ?? state.violation?.message;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<SettlementKind>(
              segments: [
                for (final option in SettlementKind.values)
                  ButtonSegment(
                    value: option,
                    label: Text(option.label),
                    enabled: state.unavailableReason(option) == null,
                    icon: Icon(_icon(option), size: 18.r),
                  ),
              ],
              selected: {kind},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                cubit.setKind(selection.first);
                setState(() => _generation++);
              },
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              SettlementSheet.describe(kind, tx),
              style: textTheme.bodySmall,
            ),
            if (reasons.isNotEmpty) ...[
              SizedBox(height: AppSpacing.xs.h),
              for (final reason in reasons)
                Text(
                  reason,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
            ],
            SizedBox(height: AppSpacing.lg.h),
            AppMoneyField(
              key: ValueKey('amount-${kind.key}-$_generation'),
              currency: currency,
              label: '${kind.label} amount',
              initialMinor: state.amountMinor,
              enabled: unavailable == null,
              errorText: amountError,
              helperText: amountError == null
                  ? '${kind == SettlementKind.refund ? 'Refundable' : 'Due'} '
                        '${Money.format(state.maxAmount, currency)}'
                  : null,
              onChanged: cubit.setAmount,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: unavailable == null && state.maxAmount > 0
                    ? () {
                        cubit.fillFull();
                        setState(() => _generation++);
                      }
                    : null,
                icon: const Icon(Icons.vertical_align_top_rounded),
                label: Text(
                  '$fullLabel (${Money.format(state.maxAmount, currency)})',
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm.h),
            LedgerDateField(
              label: 'Date the money moved',
              value: state.date,
              last: state.today,
              errorText: state.errors['date'],
              helperText: 'Separate from the transaction date.',
              onChanged: (day) {
                if (day != null) cubit.setDate(day);
              },
            ),
            if (kind != SettlementKind.credit) ...[
              SizedBox(height: AppSpacing.lg.h),
              AppTextField(
                key: ValueKey('method-${state.method.isEmpty}'),
                label: 'Method (optional)',
                hint: 'Cash, UPI, bank transfer…',
                initialValue: state.method,
                maxLength: PaymentMethods.maxLength,
                onChanged: cubit.setMethod,
              ),
              SizedBox(height: AppSpacing.xs.h),
              Wrap(
                spacing: AppSpacing.sm.w,
                children: [
                  for (final method in PaymentMethods.common)
                    ChoiceChip(
                      label: Text(method),
                      selected: state.method == method,
                      onSelected: (_) => cubit.setMethod(method),
                    ),
                ],
              ),
            ],
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              label: 'Note (optional)',
              maxLength: SettlementFormCubit.maxNoteLength,
              maxLines: 2,
              minLines: 1,
              errorText: state.errors['note'],
              textCapitalization: TextCapitalization.sentences,
              onChanged: cubit.setNote,
            ),
            SizedBox(height: AppSpacing.lg.h),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: state.preview == null
                  ? const SizedBox(width: double.infinity)
                  : _Preview(
                      before: tx.balance,
                      after: state.preview!,
                      status: state.previewStatus,
                      currency: currency,
                      inflow: tx.isInflow,
                      includesPending: state.previewIncludesPending,
                    ),
            ),
            if (state.submitStatus.isFailure &&
                state.errors.isEmpty &&
                state.submitStatus.message.isNotEmpty) ...[
              SizedBox(height: AppSpacing.md.h),
              Text(
                state.submitStatus.message,
                style: textTheme.bodySmall?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            if (!widget.online) ...[
              SizedBox(height: AppSpacing.md.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 16.r,
                    color: context.colors.warning,
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      SettlementSheet.queuedNote,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: AppSpacing.lg.h),
            AppButton(
              label: 'Record ${kind.label.toLowerCase()}',
              icon: _icon(kind),
              isLoading: state.submitStatus.isLoading,
              onPressed: state.canSubmit
                  ? () => unawaited(cubit.submit())
                  : null,
            ),
          ],
        );
      },
    );
  }

  static IconData _icon(SettlementKind kind) => switch (kind) {
    SettlementKind.payment => Icons.payments_outlined,
    SettlementKind.refund => Icons.undo_rounded,
    SettlementKind.credit => Icons.local_offer_outlined,
  };
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.before,
    required this.after,
    required this.status,
    required this.currency,
    required this.inflow,
    this.includesPending = false,
  });

  /// [after] also counts settlements still waiting to sync; [before] is the
  /// server's balance.
  final bool includesPending;

  static const String pendingTitle = 'After this and pending actions';

  final Balance before;
  final Balance after;
  final PaymentStatus? status;
  final Currency currency;
  final bool inflow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final figure = AppTextStyles.tabular(textTheme.bodyMedium!);
    Widget row(String label, int from, int to) => Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodySmall)),
          Text(
            from == to
                ? Money.format(to, currency)
                : '${Money.format(from, currency)} → '
                      '${Money.format(to, currency)}',
            style: figure.copyWith(
              color: from == to ? null : context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: context.colors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  includesPending ? pendingTitle : 'After this',
                  style: textTheme.labelMedium,
                ),
              ),
              if (status != null) AppStatusChip.payment(status!),
            ],
          ),
          SizedBox(height: AppSpacing.sm.h),
          row('Outstanding', before.outstanding, after.outstanding),
          row(
            inflow ? 'Cash received' : 'Cash paid',
            before.paid,
            after.paid,
          ),
          if (before.refunded != after.refunded || after.refunded > 0)
            row('Refunded', before.refunded, after.refunded),
          if (before.credited != after.credited || after.credited > 0)
            row('Credits', before.credited, after.credited),
          row(
            inflow ? 'Recognised income' : 'Recognised expense',
            before.effective,
            after.effective,
          ),
        ],
      ),
    );
  }
}
