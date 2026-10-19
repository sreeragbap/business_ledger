import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_status.dart';
import 'package:business_ledger/core/theme/app_colors.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_button.dart';
import 'package:business_ledger/core/widgets/app_card.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/core/widgets/app_fade_in.dart';
import 'package:business_ledger/core/widgets/app_section.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/sync/logic/sync_cubit/sync_cubit.dart';
import 'package:business_ledger/features/sync/widgets/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Settings › Sync: the Cloud sync switch, where things stand, and the
/// actions waiting in the outbox (retry or discard the ones the server
/// refused).
@RoutePage()
class SyncScreen extends StatelessWidget implements AutoRouteWrapper {
  const SyncScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) =>
      BlocProvider<SyncCubit>.value(value: getIt<SyncCubit>(), child: this);

  @override
  Widget build(BuildContext context) => const SyncView();
}

/// The body of [SyncScreen]; reads [SyncCubit].
class SyncView extends StatelessWidget {
  const SyncView({super.key});

  static const String switchExplanation =
      'On: changes upload as soon as you are online. Off: this device works '
      'from its own copy, and everything you do waits here until you turn it '
      'back on. Payments, confirms, edits and cancels are checked by the '
      'server when they sync, and may be refused if something changed.';

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncCubit, SyncState>(
      listenWhen: (p, c) =>
          p.actionStatus != c.actionStatus && !c.actionStatus.isLoading,
      listener: (context, state) {
        final status = state.actionStatus;
        if (status.message.isEmpty) return;
        showAppSnackBar(
          context,
          status.message,
          kind: status.isFailure
              ? AppSnackBarKind.error
              : AppSnackBarKind.success,
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Sync')),
        body: BlocBuilder<SyncCubit, SyncState>(
          builder: (context, state) {
            final cubit = context.read<SyncCubit>();
            final status = state.status;
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal.w,
                vertical: AppSpacing.sm.h,
              ),
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    secondary: const Icon(Icons.cloud_sync_outlined),
                    title: const Text('Cloud sync'),
                    subtitle: const Text(switchExplanation),
                    isThreeLine: true,
                    value: status.syncEnabled,
                    onChanged: state.actionStatus.isLoading
                        ? null
                        : (enabled) =>
                              unawaited(cubit.setEnabled(enabled: enabled)),
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
                const AppSectionLabel('Status'),
                _StatusCard(status: status, onSyncNow: cubit.syncNow),
                SizedBox(height: AppSpacing.xl.h),
                AppSectionLabel(
                  state.entries.isEmpty
                      ? 'Waiting to sync'
                      : 'Waiting to sync · ${state.entries.length}',
                ),
                AnimatedSwitcher(
                  duration: AppMotion.medium,
                  child: state.entries.isEmpty
                      ? const _NothingWaiting(key: ValueKey('empty'))
                      : AppCard(
                          key: const ValueKey('list'),
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (final (index, entry)
                                  in state.entries.indexed) ...[
                                if (index > 0) const Divider(),
                                AppFadeIn(
                                  child: OutboxEntryTile(
                                    entry: entry,
                                    onRetry: () =>
                                        unawaited(cubit.retry(entry.id)),
                                    onDiscard: () =>
                                        unawaited(_discard(context, entry)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
                SizedBox(height: AppSpacing.xxl.h),
              ],
            );
          },
        ),
      ),
    );
  }

  static Future<void> _discard(BuildContext context, OutboxEntry entry) async {
    final cubit = context.read<SyncCubit>();
    final dependents = cubit.dependentsOf(entry.id);
    final message = dependents.isEmpty
        ? '"${entry.label}" will not be sent. Nothing changes on the server.'
        : '"${entry.label}" will not be sent, nor '
              '${dependents.length == 1 ? 'the later action' : 'the '
                        '${dependents.length} later actions'} on the same '
              'transaction that depend on it:\n'
              '${dependents.map((e) => '• ${e.label}').join('\n')}';
    final ok = await showAppConfirmDialog(
      context: context,
      title: 'Discard this action?',
      message: message,
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (ok) await cubit.discard(entry.id);
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.onSyncNow});

  final SyncStatus status;
  final Future<void> Function() onSyncNow;

  static String _when(DateTime? time) => time == null
      ? 'Not yet on this device'
      : DateFormat('d MMM, h:mm a', 'en_US').format(time.toLocal());

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final info = SyncStatusBanner.describe(status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                info?.icon ?? Icons.cloud_done_outlined,
                size: 20.r,
                color: info?.colour ?? AppColors.income,
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text(
                  info?.message ?? 'Everything is synced',
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          _Line(
            label: 'Connection',
            value: status.online ? 'Online' : 'Offline',
          ),
          _Line(
            label: 'Cloud sync',
            value: status.syncEnabled ? 'On' : 'Off on this device',
          ),
          _Line(
            label: 'Local changes',
            value: status.hasLocalChanges
                ? '${status.localChanges} not uploaded yet'
                : 'Uploaded',
          ),
          _Line(label: 'Last synced', value: _when(status.lastSyncedAt)),
          SizedBox(height: AppSpacing.md.h),
          AppButton.secondary(
            label: 'Sync now',
            icon: Icons.sync_rounded,
            isLoading: status.syncing,
            onPressed: status.canSync ? () => unawaited(onSyncNow()) : null,
          ),
          if (!status.canSync) ...[
            SizedBox(height: AppSpacing.sm.h),
            Text(
              status.syncEnabled
                  ? 'Waiting for a connection.'
                  : 'Turn Cloud sync on to upload.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodySmall)),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _NothingWaiting extends StatelessWidget {
  const _NothingWaiting({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 20.r,
          color: AppColors.income,
        ),
        SizedBox(width: AppSpacing.sm.w),
        Expanded(
          child: Text(
            'Nothing waiting. Drafts, settings, payments, confirms and other '
            'changes made offline appear here until they sync.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

/// One queued action: what it is, when, its state, and (for a refused one)
/// the server's reason with retry and discard.
class OutboxEntryTile extends StatelessWidget {
  const OutboxEntryTile({
    required this.entry,
    required this.onRetry,
    required this.onDiscard,
    super.key,
  });

  final OutboxEntry entry;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  static IconData iconOf(OutboxKind kind) => switch (kind) {
    OutboxKind.confirm => Icons.check_circle_outline_rounded,
    OutboxKind.settle => Icons.payments_outlined,
    OutboxKind.edit => Icons.edit_outlined,
    OutboxKind.cancel => Icons.block_rounded,
    OutboxKind.upsert => Icons.cloud_upload_outlined,
    OutboxKind.update => Icons.cloud_sync_outlined,
  };

  static String statusOf(OutboxEntry entry) => switch (entry.status) {
    OutboxStatus.syncing => 'Syncing…',
    OutboxStatus.failed => 'Refused',
    OutboxStatus.pending when entry.lastError != null =>
      'Will retry — ${entry.lastError!.message}',
    OutboxStatus.pending => 'Waiting to sync',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final failed = entry.isFailed;
    final when = DateFormat(
      'd MMM, h:mm a',
      'en_US',
    ).format(entry.createdAt.toLocal());
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.md.h,
        AppSpacing.sm.w,
        AppSpacing.md.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconOf(entry.kind),
            size: 20.r,
            color: failed ? AppColors.error : AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label, style: textTheme.bodyLarge),
                SizedBox(height: AppSpacing.xxs.h),
                Text(
                  '$when · ${statusOf(entry)}',
                  style: textTheme.bodySmall,
                ),
                if (failed && entry.lastError != null) ...[
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    entry.lastError!.message,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                if (failed)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs.h),
                    child: Wrap(
                      spacing: AppSpacing.sm.w,
                      children: [
                        AppButton.text(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          onPressed: onRetry,
                        ),
                        AppButton.text(
                          label: 'Discard',
                          icon: Icons.delete_outline_rounded,
                          destructive: true,
                          onPressed: onDiscard,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!failed && !entry.isSyncing)
            IconButton(
              tooltip: 'Discard',
              icon: const Icon(Icons.close_rounded),
              onPressed: onDiscard,
            ),
        ],
      ),
    );
  }
}
