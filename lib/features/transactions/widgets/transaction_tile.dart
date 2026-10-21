import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/money/money.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/pending_sync_badge.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Hero tags shared by the list row and the detail header.
abstract final class TransactionHeroTags {
  static String amount(String id) => 'transaction-amount-$id';
  static String title(String id) => 'transaction-title-$id';
}

/// The colour that carries a transaction's direction and state.
Color transactionColour(LedgerTransaction tx, AppPalette palette) {
  if (tx.isCancelled) return palette.textTertiary;
  if (tx.isRefundEntry) return palette.refund;
  if (tx.isDraft) return palette.textSecondary;
  return tx.isInflow ? palette.income : palette.expense;
}

/// `+₹1,200.00` / `−₹1,200.00`: the sign says the direction without colour.
String signedAmount(LedgerTransaction tx, Currency currency, [int? minor]) {
  final value = Money.format(minor ?? tx.totalMinor, currency);
  final direction = tx.effectiveDirection;
  if (direction == null) return value;
  return direction == Direction.inflow ? '+$value' : '−$value';
}

/// One row of the transactions list.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.currency,
    required this.today,
    this.onTap,
    this.heroEnabled = true,
    this.syncMark = SyncMark.none,
    super.key,
  });

  final LedgerTransaction transaction;
  final Currency currency;
  final String today;
  final VoidCallback? onTap;
  final bool heroEnabled;

  /// Actions on this entry still waiting in the outbox.
  final SyncMark syncMark;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final textTheme = Theme.of(context).textTheme;
    final colour = transactionColour(tx, context.colors);
    final overdue = tx.isOverdue(today);
    final amount = signedAmount(tx, currency);
    final meta = [
      if (tx.partyName != null && tx.partyName != tx.title) tx.partyName!,
      if (tx.categoryName != null && tx.categoryName != tx.title)
        tx.categoryName!,
      if (tx.isRefundEntry) 'Refund entry' else tx.type.label,
    ].join(' · ');
    final date = overdue && tx.dueDate != null
        ? 'Due ${LedgerDates.formatShort(tx.dueDate)}'
        : LedgerDates.formatShort(tx.date);
    final status = TransactionStatusChip.labelFor(tx, today);

    final icon = tx.isRefundEntry
        ? Icons.undo_rounded
        : tx.effectiveDirection == null
        ? Icons.swap_vert_rounded
        : tx.isInflow
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;

    final amountText = Text(
      amount,
      maxLines: 1,
      style: AppTextStyles.tabular(textTheme.titleSmall!).copyWith(
        color: colour,
        decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
        decorationColor: colour,
      ),
    );
    final titleText = Text(
      tx.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.titleSmall?.copyWith(
        fontStyle: tx.isDraft ? FontStyle.italic : null,
        color: tx.isCancelled ? context.colors.textSecondary : null,
      ),
    );

    return Semantics(
      button: onTap != null,
      label: [
        tx.title,
        if (meta.isNotEmpty) meta,
        amount,
        status,
        if (date.isNotEmpty) date,
        if (syncMark == SyncMark.failed)
          'a queued action needs attention'
        else if (syncMark == SyncMark.pending || tx.hasPendingWrites)
          'waiting to sync',
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs.w,
              vertical: AppSpacing.sm.h,
            ),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: AppColors.tint(colour),
                    borderRadius: BorderRadius.circular(AppRadius.md.r),
                    border: tx.isDraft
                        ? Border.all(color: context.colors.borderStrong)
                        : null,
                  ),
                  child: Icon(icon, color: colour, size: 20.r),
                ),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _maybeHero(TransactionHeroTags.title(tx.id), titleText),
                      SizedBox(height: AppSpacing.xxs.h),
                      Row(
                        children: [
                          if (syncMark != SyncMark.none) ...[
                            Flexible(
                              flex: 2,
                              child: PendingSyncBadge(mark: syncMark),
                            ),
                            SizedBox(width: AppSpacing.xs.w),
                          ] else if (tx.hasPendingWrites) ...[
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 13.r,
                              color: context.colors.textTertiary,
                            ),
                            SizedBox(width: AppSpacing.xs.w),
                          ],
                          Expanded(
                            flex: 3,
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _maybeHero(TransactionHeroTags.amount(tx.id), amountText),
                    SizedBox(height: AppSpacing.xs.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (date.isNotEmpty) ...[
                          Text(
                            date,
                            style: textTheme.bodySmall?.copyWith(
                              color: overdue ? context.colors.warning : null,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs.w),
                        ],
                        TransactionStatusChip(transaction: tx, today: today),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _maybeHero(String tag, Widget child) => heroEnabled
      ? Hero(
          tag: tag,
          child: Material(type: MaterialType.transparency, child: child),
        )
      : child;
}
