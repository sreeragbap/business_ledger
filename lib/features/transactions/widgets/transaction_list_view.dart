import 'dart:async';

import 'package:business_ledger/core/ledger/ledger_enums.dart';
import 'package:business_ledger/core/money/currency.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_shimmer.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/transactions/domain/const/transaction_filters.dart';
import 'package:business_ledger/features/transactions/domain/models/ledger_transaction.dart';
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart';
import 'package:business_ledger/features/transactions/logic/transaction_list_cubit/transaction_list_cubit.dart';
import 'package:business_ledger/features/transactions/widgets/animated_presence_sliver.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_filter_bar.dart';
import 'package:business_ledger/features/transactions/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The transactions list body: search and filters, date-sectioned rows that
/// animate in and out, pull to refresh, endless scroll, and an empty state
/// that speaks to the active filter. Navigation is the caller's, through
/// [onOpen] and [onCreate].
class TransactionListView extends StatelessWidget {
  const TransactionListView({
    required this.onOpen,
    required this.onCreate,
    this.title = 'Transactions',
    this.actions = const [],
    this.heroEnabled = true,
    super.key,
  });

  final String title;
  final List<Widget> actions;
  final ValueChanged<LedgerTransaction> onOpen;

  /// Quick add, with the most recently used type preselected.
  final ValueChanged<TransactionType> onCreate;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final role = context.select<BusinessScopeCubit, Role>(
      (cubit) => cubit.state.role,
    );
    return BlocListener<TransactionListCubit, TransactionListState>(
      listenWhen: (p, c) =>
          c.loadStatus.isFailure &&
          c.items != null &&
          p.loadStatus != c.loadStatus,
      listener: (context, state) => showAppSnackBar(
        context,
        state.loadStatus.message,
        kind: AppSnackBarKind.error,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          titleSpacing: AppSpacing.screenHorizontal.w,
          actions: [
            ...actions,
            SizedBox(width: AppSpacing.sm.w),
          ],
        ),
        floatingActionButton: role.canEditConfig
            ? FloatingActionButton.extended(
                heroTag: null,
                tooltip: 'New transaction',
                onPressed: () => onCreate(
                  context.read<TransactionListCubit>().state.recentType,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New transaction'),
              )
            : null,
        body: Column(
          children: [
            const TransactionFilterBar(),
            Expanded(
              child: _Body(
                onOpen: onOpen,
                onCreate: onCreate,
                canCreate: role.canEditConfig,
                heroEnabled: heroEnabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

sealed class _Row {
  const _Row();
}

class _Header extends _Row {
  const _Header(this.label, this.count);

  final String label;
  final int count;
}

class _Item extends _Row {
  const _Item(this.transaction);

  final LedgerTransaction transaction;
}

class _Body extends StatelessWidget {
  const _Body({
    required this.onOpen,
    required this.onCreate,
    required this.canCreate,
    required this.heroEnabled,
  });

  final ValueChanged<LedgerTransaction> onOpen;
  final ValueChanged<TransactionType> onCreate;
  final bool canCreate;
  final bool heroEnabled;

  @override
  Widget build(BuildContext context) {
    final currency = context.select<BusinessScopeCubit, Currency>(
      (cubit) => cubit.state.business?.currency ?? Currency.inr,
    );
    final cubit = context.read<TransactionListCubit>();
    return BlocBuilder<TransactionListCubit, TransactionListState>(
      builder: (context, state) {
        final items = state.items;
        final Widget child;
        if (items == null) {
          child = state.loadStatus.isFailure
              ? AppErrorState(
                  key: const ValueKey('error'),
                  message: state.loadStatus.message,
                  onRetry: () => unawaited(cubit.refresh()),
                )
              : const TransactionListSkeleton(key: ValueKey('loading'));
        } else {
          child = RefreshIndicator(
            key: const ValueKey('list'),
            onRefresh: cubit.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final metrics = notification.metrics;
                if (metrics.axis == Axis.vertical &&
                    metrics.extentAfter < 400 &&
                    state.hasMore &&
                    !state.loadingMore) {
                  unawaited(cubit.loadMore());
                }
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.loadStatus.isLoading)
                    const SliverToBoxAdapter(
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (items.isNotEmpty && !state.exactOrder)
                    SliverToBoxAdapter(child: _PartialOrderNote(state)),
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        filter: state.filter,
                        canCreate: canCreate,
                        onCreate: () => onCreate(state.recentType),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal.w,
                      ),
                      sliver: AnimatedPresenceSliver<_Row>(
                        items: [
                          for (final section in state.sections) ...[
                            _Header(section.label, section.items.length),
                            for (final tx in section.items) _Item(tx),
                          ],
                        ],
                        keyOf: (row) => switch (row) {
                          _Header(:final label) => 'header:$label',
                          _Item(:final transaction) => transaction.id,
                        },
                        itemBuilder: (context, row) => switch (row) {
                          _Header(:final label, :final count) => _SectionLabel(
                            label: label,
                            count: count,
                          ),
                          _Item(:final transaction) => TransactionTile(
                            transaction: transaction,
                            currency: currency,
                            today: state.today,
                            heroEnabled: heroEnabled,
                            onTap: () => onOpen(transaction),
                          ),
                        },
                      ),
                    ),
                  SliverToBoxAdapter(child: _Footer(state)),
                ],
              ),
            ),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: child,
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.lg.h,
        bottom: AppSpacing.xs.h,
        left: AppSpacing.xs.w,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PartialOrderNote extends StatelessWidget {
  const _PartialOrderNote(this.state);

  final TransactionListState state;

  @override
  Widget build(BuildContext context) {
    final count = state.items?.length ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal.w,
        AppSpacing.sm.h,
        AppSpacing.screenHorizontal.w,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14.r,
            color: AppColors.textTertiary,
          ),
          SizedBox(width: AppSpacing.xs.w),
          Expanded(
            child: Text(
              state.hasMore
                  ? '${state.filter.sort.label} among the $count loaded. '
                        'Scroll to load more.'
                  : '${state.filter.sort.label} · $count entries',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer(this.state);

  final TransactionListState state;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (state.loadingMore) {
      content = const Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (state.hasMore && state.limit >= TransactionListCubit.maxLimit) {
      content = Text(
        'Showing the first ${TransactionListCubit.maxLimit}. Narrow the '
        'filters to see the rest.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    } else if (state.hasMore) {
      content = Center(
        child: TextButton(
          onPressed: () =>
              unawaited(context.read<TransactionListCubit>().loadMore()),
          child: const Text('Load more'),
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal.w,
        AppSpacing.md.h,
        AppSpacing.screenHorizontal.w,
        // Clear of the FAB.
        96.h,
      ),
      child: content,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filter,
    required this.canCreate,
    required this.onCreate,
  });

  final TransactionFilter filter;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionListCubit>();
    final clear = AppButton.secondary(
      label: 'Clear filters',
      icon: Icons.filter_alt_off_outlined,
      expand: false,
      onPressed: () => unawaited(cubit.clearFilters()),
    );
    if (filter.hasSearch) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches for "${filter.search.trim()}"',
        message:
            'Search looks at descriptions, references, parties, '
            'categories and projects.',
        action: filter.activeCount > 0 ? clear : null,
      );
    }
    final (IconData icon, String title, String message) = switch (filter) {
      TransactionFilter(payment: PaymentFilter.overdue) => (
        Icons.event_available_rounded,
        'Nothing overdue',
        'Every open balance is within its due date.',
      ),
      TransactionFilter(payment: PaymentFilter.open) => (
        Icons.task_alt_rounded,
        'Nothing outstanding',
        'Every confirmed transaction is settled.',
      ),
      TransactionFilter(status: TransactionStatus.draft) => (
        Icons.edit_note_rounded,
        'No drafts',
        'Drafts you save, even offline, wait here until confirmed.',
      ),
      TransactionFilter(status: TransactionStatus.cancelled) => (
        Icons.block_rounded,
        'Nothing cancelled',
        'Cancelled transactions stay here for the record.',
      ),
      _ when filter.activeCount > 0 => (
        Icons.filter_alt_outlined,
        'No transactions match',
        'Try fewer filters or a wider date range.',
      ),
      _ => (
        Icons.receipt_long_outlined,
        'No transactions yet',
        'Sales, purchases, income and expenses you record will appear here.',
      ),
    };
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      action: filter.activeCount > 0
          ? clear
          : canCreate
          ? AppButton(
              label: 'New transaction',
              icon: Icons.add_rounded,
              expand: false,
              onPressed: onCreate,
            )
          : null,
    );
  }
}

/// Date header and tile-shaped rows while the first page loads.
class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal.w,
          vertical: AppSpacing.lg.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var section = 0; section < 2; section++) ...[
              const ShimmerBox(width: 90, height: 10),
              SizedBox(height: AppSpacing.md.h),
              for (var row = 0; row < 3; row++) ...[
                Row(
                  children: [
                    const ShimmerBox(
                      width: 40,
                      height: 40,
                      radius: AppRadius.md,
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(width: 150, height: 14),
                          SizedBox(height: AppSpacing.sm),
                          ShimmerBox(width: 100, height: 11),
                        ],
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShimmerBox(width: 76, height: 14),
                        SizedBox(height: AppSpacing.sm),
                        ShimmerBox(
                          width: 56,
                          height: 16,
                          radius: AppRadius.pill,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.h),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
