import 'dart:async';

import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/theme/app_text_styles.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_fade_in.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/core/widgets/pending_sync_badge.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_dates.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/logic/transaction_detail_cubit/transaction_detail_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/cancel_transaction_dialog.dart';
import 'package:business_ledger/features/transactions/widgets/detail_sections.dart';
import 'package:business_ledger/features/transactions/widgets/success_check.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_status_chip.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// The transaction detail body. Reads [TransactionDetailCubit]; navigation
/// and sheets that need other cubits are the caller's, via the callbacks.
class TransactionDetailView extends StatelessWidget {
  const TransactionDetailView({
    required this.currency,
    required this.onEdit,
    required this.onOpenTransaction,
    required this.onRecordSettlement,
    required this.onDocuments,
    required this.onDuplicated,
    this.onOpenSync,
    super.key,
  });

  final Currency currency;
  final ValueChanged<LedgerTransaction> onEdit;

  /// Another transaction (a refund entry, or a refund's original).
  final ValueChanged<String> onOpenTransaction;
  final ValueChanged<SettlementKind> onRecordSettlement;
  final ValueChanged<LedgerTransaction> onDocuments;

  /// A copy was saved as a new draft: open it.
  final ValueChanged<String> onDuplicated;

  /// The Sync screen, to review a queued action the server refused.
  final VoidCallback? onOpenSync;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionDetailCubit, TransactionDetailState>(
      listenWhen: (p, c) =>
          p.actionStatus != c.actionStatus && !c.actionStatus.isLoading,
      listener: _onAction,
      child: BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
        builder: (context, state) {
          final tx = state.transaction;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                tx == null
                    ? 'Transaction'
                    : tx.isRefundEntry
                    ? 'Refund'
                    : tx.type.label,
              ),
              actions: tx == null ? null : _appBarActions(context, state),
            ),
            body: AnimatedSwitcher(
              duration: AppMotion.medium,
              child: tx != null
                  ? _Content(
                      key: const ValueKey('content'),
                      state: state,
                      currency: currency,
                      onOpenTransaction: onOpenTransaction,
                      onOpenSync: onOpenSync,
                    )
                  : state.loadStatus.isFailure
                  ? AppErrorState(
                      key: const ValueKey('error'),
                      message: state.loadStatus.message,
                    )
                  : const _Skeleton(key: ValueKey('loading')),
            ),
            bottomNavigationBar: tx == null
                ? null
                : _ActionBar(
                    state: state,
                    onEdit: () => onEdit(tx),
                    onRecord: onRecordSettlement,
                    onOpenTransaction: onOpenTransaction,
                  ),
          );
        },
      ),
    );
  }

  void _onAction(BuildContext context, TransactionDetailState state) {
    final status = state.actionStatus;
    if (status.isFailure) {
      showAppSnackBar(context, status.message, kind: AppSnackBarKind.error);
      return;
    }
    if (!status.isSuccess) return;
    if (state.actionQueued) {
      showAppSnackBar(context, status.message, kind: AppSnackBarKind.success);
      return;
    }
    switch (state.action) {
      case DetailAction.confirm || DetailAction.confirmPaid:
        showSuccessCheck(context, label: status.message);
      case DetailAction.delete:
        showAppSnackBar(context, status.message);
        unawaited(Navigator.of(context).maybePop());
      case DetailAction.duplicate:
        if (state.duplicatedId case final id?) onDuplicated(id);
      case DetailAction.cancel || DetailAction.edit || null:
        showAppSnackBar(context, status.message);
    }
  }

  List<Widget> _appBarActions(
    BuildContext context,
    TransactionDetailState state,
  ) {
    final tx = state.transaction!;
    final cubit = context.read<TransactionDetailCubit>();
    final hasDocuments =
        !tx.isDraft &&
        !tx.isRefundEntry &&
        (tx.type.documentType != null ||
            state.settlements.any((s) => s.kind == SettlementKind.payment));
    final items = <PopupMenuEntry<VoidCallback>>[
      if ((tx.isConfirmed || (tx.isDraft && state.confirmQueued)) &&
          state.role.canDoFinancial &&
          tx.isSettleable) ...[
        for (final kind in SettlementKind.values)
          PopupMenuItem(
            value: () => onRecordSettlement(kind),
            enabled: state.kindUnavailableReason(kind) == null,
            child: _MenuRow(
              icon: SettlementTimeline.iconOf(kind),
              label: switch (kind) {
                SettlementKind.payment => 'Record payment',
                SettlementKind.refund => 'Record refund',
                SettlementKind.credit => 'Add credit or discount',
              },
            ),
          ),
        const PopupMenuDivider(),
      ],
      if (tx.isDraft && state.role.canDoFinancial)
        PopupMenuItem(
          value: () => unawaited(_confirm(context, settleNow: true)),
          enabled: state.can(DetailAction.confirmPaid),
          child: const _MenuRow(
            icon: Icons.price_check_rounded,
            label: 'Confirm as paid',
          ),
        ),
      if (state.can(DetailAction.duplicate))
        PopupMenuItem(
          value: () => unawaited(cubit.duplicate()),
          child: const _MenuRow(
            icon: Icons.copy_all_outlined,
            label: 'Duplicate as draft',
          ),
        ),
      if (tx.isConfirmed && !tx.isRefundEntry && state.role.canDoFinancial)
        PopupMenuItem(
          // Tapped even when blocked, so the reason (refund first) shows.
          value: () => unawaited(_cancel(context, state)),
          child: const _MenuRow(
            icon: Icons.block_rounded,
            label: 'Cancel transaction',
            destructive: true,
          ),
        ),
      if (tx.isDraft && state.can(DetailAction.delete))
        PopupMenuItem(
          value: () => unawaited(_delete(context)),
          child: const _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete draft',
            destructive: true,
          ),
        ),
    ];
    return [
      if (hasDocuments)
        IconButton(
          tooltip: 'Invoices, bills & receipts',
          icon: const Icon(Icons.description_outlined),
          onPressed: () => onDocuments(tx),
        ),
      if (items.isNotEmpty)
        PopupMenuButton<VoidCallback>(
          tooltip: 'More actions',
          onSelected: (action) => action(),
          itemBuilder: (_) => items,
        ),
      SizedBox(width: AppSpacing.xs.w),
    ];
  }

  static Future<void> _confirm(
    BuildContext context, {
    bool settleNow = false,
  }) async {
    final cubit = context.read<TransactionDetailCubit>();
    final queued = !cubit.state.online;
    final message = settleNow
        ? 'It will count in your reports, and the full amount is recorded '
              'as paid today.'
        : 'It will count in your reports. After this it can be edited or '
              'cancelled, but not turned back into a draft.';
    final ok = await showAppConfirmDialog(
      context: context,
      title: settleNow ? 'Confirm as paid?' : 'Confirm this transaction?',
      message: queued ? '$message\n\n$queuedConfirmNote' : message,
      confirmLabel: settleNow ? 'Confirm & pay' : 'Confirm',
    );
    if (ok) await cubit.confirm(settleNow: settleNow);
  }

  static const String queuedConfirmNote =
      'Not syncing right now: the confirm is kept on this device and '
      'applied when synced. It may be refused if something changed '
      'meanwhile.';

  static Future<void> _cancel(
    BuildContext context,
    TransactionDetailState state,
  ) async {
    final cubit = context.read<TransactionDetailCubit>();
    // Explain a refusal (money still held) before asking for a reason.
    if (state.blockedReason(DetailAction.cancel) != null) {
      await cubit.cancel();
      return;
    }
    final reason = await showCancelTransactionDialog(
      context,
      queued: !state.online,
    );
    if (reason != null) await cubit.cancel(reason: reason);
  }

  static Future<void> _delete(BuildContext context) async {
    final cubit = context.read<TransactionDetailCubit>();
    final ok = await showAppConfirmDialog(
      context: context,
      title: 'Delete this draft?',
      message: 'Drafts never counted anywhere, so nothing else changes.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await cubit.deleteDraft();
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 20.r,
        color: destructive ? AppColors.error : AppColors.textSecondary,
      ),
      SizedBox(width: AppSpacing.md.w),
      Text(
        label,
        style: destructive ? const TextStyle(color: AppColors.error) : null,
      ),
    ],
  );
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.currency,
    required this.onOpenTransaction,
    this.onOpenSync,
    super.key,
  });

  final TransactionDetailState state;
  final Currency currency;
  final ValueChanged<String> onOpenTransaction;
  final VoidCallback? onOpenSync;

  @override
  Widget build(BuildContext context) {
    final tx = state.transaction!;
    final gap = SizedBox(height: AppSpacing.xl.h);
    final details = _details(tx);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal.w,
        AppSpacing.sm.h,
        AppSpacing.screenHorizontal.w,
        AppSpacing.huge.h,
      ),
      children: [
        _Header(
          transaction: tx,
          today: state.today,
          currency: currency,
          syncMark: state.syncMark,
        ),
        ..._banners(context, tx),
        gap,
        AppFadeIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionLabel('Balance'),
              BalanceBreakdown(transaction: tx, currency: currency),
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: state.hasQueued
                    ? Padding(
                        padding: EdgeInsets.only(top: AppSpacing.md.h),
                        child: QueuedActionsCard(
                          entries: state.queued,
                          onReview: onOpenSync,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
        if (tx.lineItems.isNotEmpty) ...[
          gap,
          AppSectionLabel('Items · ${tx.lineItems.length}'),
          LineItemsTable(lines: tx.lineItems, currency: currency),
        ],
        if (details.isNotEmpty) ...[
          gap,
          const AppSectionLabel('Details'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: details,
            ),
          ),
        ],
        if (state.settlements.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md.h),
          AppCollapsibleSection(
            title: 'Payments, refunds & credits',
            count: state.settlements.length,
            initiallyExpanded: true,
            child: SettlementTimeline(
              settlements: state.settlements,
              currency: currency,
              onOpenLinked: onOpenTransaction,
            ),
          ),
        ],
        if (state.linked.isNotEmpty) ...[
          AppCollapsibleSection(
            title: 'Refund entries',
            count: state.linked.length,
            child: Column(
              children: [
                for (final entry in state.linked)
                  TransactionTile(
                    transaction: entry,
                    currency: currency,
                    today: state.today,
                    heroEnabled: false,
                    onTap: () => onOpenTransaction(entry.id),
                  ),
              ],
            ),
          ),
        ],
        if (state.showsAudit && state.audit != null)
          AppCollapsibleSection(
            title: 'History',
            count: state.audit!.length,
            child: AuditHistory(entries: state.audit!),
          ),
      ],
    );
  }

  List<Widget> _banners(BuildContext context, LedgerTransaction tx) {
    final banners = <Widget>[];
    void add(IconData icon, Color colour, String text, {Widget? action}) =>
        banners.add(
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md.h),
            child: _Banner(
              icon: icon,
              colour: colour,
              text: text,
              action: action,
            ),
          ),
        );
    if (tx.isCancelled) {
      final when = tx.cancelledAt == null
          ? ''
          : ' on ${DateFormat('d MMM yyyy', 'en_US').format(tx.cancelledAt!)}';
      add(
        Icons.block_rounded,
        AppColors.error,
        'VOID — cancelled$when. It no longer counts anywhere'
        '${tx.cancelReason.isEmpty ? '.' : '. Reason: ${tx.cancelReason}'}',
      );
    }
    if (tx.isDraft) {
      add(
        Icons.edit_note_rounded,
        AppColors.textSecondary,
        tx.hasPendingWrites
            ? 'Draft saved on this device; it will sync when online. '
                  'Drafts count nowhere until confirmed.'
            : 'Draft — counts nowhere until it is confirmed.',
      );
    }
    if (tx.isRefundEntry && tx.linkedTransactionId != null) {
      add(
        Icons.undo_rounded,
        AppColors.refund,
        'A refund recorded against another transaction. Its money is '
        'carried by the original.',
        action: TextButton(
          onPressed: () => onOpenTransaction(tx.linkedTransactionId!),
          child: const Text('View original'),
        ),
      );
    }
    if (tx.isConfirmed && tx.dueDate != null && tx.outstandingMinor > 0) {
      final overdue = tx.isOverdue(state.today);
      add(
        overdue ? Icons.schedule_rounded : Icons.event_outlined,
        overdue ? AppColors.warning : AppColors.info,
        overdue
            ? 'Overdue — was due ${LedgerDates.format(tx.dueDate)}.'
            : 'Due ${LedgerDates.format(tx.dueDate)}.',
      );
    }
    return banners;
  }

  List<Widget> _details(LedgerTransaction tx) {
    CustomField? fieldFor(String id) =>
        state.fields.where((f) => f.id == id).firstOrNull;
    return [
      DetailLine(
        label: 'Date',
        value: LedgerDates.format(tx.date).ifEmpty('Not set'),
        icon: Icons.event_outlined,
      ),
      if (tx.categoryName != null)
        DetailLine(
          label: 'Category',
          value: tx.categoryName!,
          icon: Icons.category_outlined,
        ),
      if (tx.partyName != null)
        DetailLine(
          label: tx.isInflow ? 'Customer' : 'Supplier',
          value: tx.partyName!,
          icon: Icons.person_outline_rounded,
        ),
      if (tx.projectName != null)
        DetailLine(
          label: 'Project',
          value: tx.projectName!,
          icon: Icons.work_outline_rounded,
        ),
      if (tx.reference.isNotEmpty)
        DetailLine(
          label: 'Reference',
          value: tx.reference,
          icon: Icons.tag_rounded,
        ),
      if (tx.paymentMethod.isNotEmpty)
        DetailLine(
          label: 'Payment method',
          value: tx.paymentMethod,
          icon: Icons.account_balance_wallet_outlined,
        ),
      for (final entry in tx.customFields.entries)
        DetailLine(
          label: fieldFor(entry.key)?.label ?? 'Field',
          value: customFieldText(fieldFor(entry.key), entry.value),
          icon: Icons.tune_rounded,
        ),
      if (tx.notes.isNotEmpty)
        DetailLine(
          label: 'Notes',
          value: tx.notes,
          icon: Icons.notes_rounded,
        ),
    ];
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.transaction,
    required this.today,
    required this.currency,
    required this.syncMark,
  });

  final LedgerTransaction transaction;
  final String today;
  final Currency currency;
  final SyncMark syncMark;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final textTheme = Theme.of(context).textTheme;
    final colour = transactionColour(tx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: TransactionHeroTags.title(tx.id),
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              tx.title,
              style: textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Hero(
          tag: TransactionHeroTags.amount(tx.id),
          child: Material(
            type: MaterialType.transparency,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                signedAmount(tx, currency),
                style: AppTextStyles.tabular(textTheme.displayMedium!).copyWith(
                  color: colour,
                  decoration: tx.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: colour,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Wrap(
          spacing: AppSpacing.sm.w,
          runSpacing: AppSpacing.xs.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TransactionStatusChip(transaction: tx, today: today),
            if (tx.isConfirmed &&
                tx.paymentStatus != null &&
                tx.paymentStatus != PaymentStatus.notApplicable)
              _TypeChip(label: tx.status.label),
            _TypeChip(
              label: tx.effectiveDirection == null
                  ? tx.type.label
                  : '${tx.type.label} · money '
                        '${tx.isInflow ? 'in' : 'out'}',
            ),
            if (syncMark != SyncMark.none) PendingSyncBadge(mark: syncMark),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.sm.w,
      vertical: AppSpacing.xxs.h + 1,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: AppRadius.chip,
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.colour,
    required this.text,
    this.action,
  });

  final IconData icon;
  final Color colour;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md.w,
      vertical: AppSpacing.sm.h,
    ),
    decoration: BoxDecoration(
      color: AppColors.tint(colour),
      borderRadius: BorderRadius.circular(AppRadius.md.r),
    ),
    child: Row(
      children: [
        Icon(icon, color: colour, size: 20.r),
        SizedBox(width: AppSpacing.sm.w),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
        ?action,
      ],
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.onEdit,
    required this.onRecord,
    required this.onOpenTransaction,
  });

  final TransactionDetailState state;
  final VoidCallback onEdit;
  final ValueChanged<SettlementKind> onRecord;
  final ValueChanged<String> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final tx = state.transaction!;
    final textTheme = Theme.of(context).textTheme;
    final busy = state.actionStatus.isLoading;
    final buttons = <Widget>[];
    String? note;

    if (tx.isRefundEntry) {
      if (tx.linkedTransactionId != null) {
        buttons.add(
          AppButton.secondary(
            label: 'View original transaction',
            icon: Icons.open_in_new_rounded,
            onPressed: () => onOpenTransaction(tx.linkedTransactionId!),
          ),
        );
      }
    } else if (tx.isCancelled) {
      note = 'Cancelled transactions are read-only.';
    } else if (tx.isDraft && !state.confirmQueued) {
      if (state.can(DetailAction.edit)) {
        buttons.add(
          AppButton.secondary(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: busy ? null : onEdit,
          ),
        );
      }
      if (state.role.canDoFinancial) {
        buttons.add(
          AppButton(
            label: 'Confirm',
            icon: Icons.check_circle_outline_rounded,
            isLoading:
                busy &&
                (state.action == DetailAction.confirm ||
                    state.action == DetailAction.confirmPaid),
            onPressed: state.can(DetailAction.confirm) && !busy
                ? () => unawaited(
                    TransactionDetailView._confirm(context),
                  )
                : null,
          ),
        );
        note = state.blockedReason(DetailAction.confirm);
      } else if (state.role.canEditConfig) {
        note = 'An admin or owner confirms drafts.';
      }
    } else {
      if (state.can(DetailAction.edit)) {
        buttons.add(
          AppButton.secondary(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: busy ? null : onEdit,
          ),
        );
      }
      final kind = tx.isSettleable
          ? [
              SettlementKind.payment,
              SettlementKind.refund,
            ].where((k) => state.kindUnavailableReason(k) == null).firstOrNull
          : null;
      if (kind != null) {
        buttons.add(
          AppButton(
            label: kind == SettlementKind.payment
                ? (tx.isInflow ? 'Record payment' : 'Record payment made')
                : 'Record refund',
            icon: SettlementTimeline.iconOf(kind),
            onPressed: busy ? null : () => onRecord(kind),
          ),
        );
      }
      if (!state.role.canDoFinancial) {
        note = state.role.canEditConfig
            ? 'Only admins and owners change confirmed transactions.'
            : null;
      }
    }

    if (!state.online &&
        state.role.canDoFinancial &&
        !tx.isCancelled &&
        !tx.isRefundEntry) {
      note ??=
          'Not syncing right now: money actions are kept on this device and '
          'applied when synced.';
    }

    if (buttons.isEmpty && note == null) {
      if (state.role.canEditConfig || tx.isCancelled) {
        return const SizedBox.shrink();
      }
      note = 'View only.';
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal.w,
            AppSpacing.md.h,
            AppSpacing.screenHorizontal.w,
            AppSpacing.md.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note != null)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: buttons.isEmpty ? 0 : AppSpacing.sm.h,
                  ),
                  child: Text(
                    note,
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (buttons.isNotEmpty)
                Row(
                  children: [
                    for (final (index, button) in buttons.indexed) ...[
                      if (index > 0) SizedBox(width: AppSpacing.md.w),
                      Expanded(child: button),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The actions on this transaction still waiting in the outbox, under the
/// balance. The balance above is the server's; these are not in it yet.
class QueuedActionsCard extends StatelessWidget {
  const QueuedActionsCard({required this.entries, this.onReview, super.key});

  final List<OutboxEntry> entries;
  final VoidCallback? onReview;

  static String statusOf(OutboxEntry entry) => switch (entry.status) {
    OutboxStatus.pending => 'waiting to sync',
    OutboxStatus.syncing => 'syncing…',
    OutboxStatus.failed =>
      "couldn't be applied: ${entry.lastError?.message ?? 'refused'}",
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final anyFailed = entries.any((entry) => entry.isFailed);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 18.r,
                color: AppColors.warning,
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text('Pending sync', style: textTheme.titleSmall),
              ),
              if (anyFailed && onReview != null)
                TextButton(onPressed: onReview, child: const Text('Review')),
            ],
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            'Not in the balance above until the server applies them.',
            style: textTheme.bodySmall,
          ),
          for (final entry in entries)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Icon(
                      entry.isFailed
                          ? Icons.error_outline_rounded
                          : Icons.schedule_rounded,
                      size: 16.r,
                      color: entry.isFailed
                          ? AppColors.error
                          : AppColors.textTertiary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      '${entry.label} — ${statusOf(entry)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: entry.isFailed ? AppColors.error : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.screenHorizontal.w),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 180, height: 18),
          SizedBox(height: AppSpacing.md),
          ShimmerBox(width: 220, height: 34),
          SizedBox(height: AppSpacing.md),
          ShimmerBox(width: 120, height: 18, radius: AppRadius.pill),
          SizedBox(height: AppSpacing.xxl),
          ShimmerBox(height: 180, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.xl),
          ShimmerBox(height: 120, radius: AppRadius.lg),
        ],
      ),
    ),
  );
}
