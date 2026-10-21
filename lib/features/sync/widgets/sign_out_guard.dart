import 'dart:async';

import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:business_ledger/features/sync/logic/sync_cubit/sync_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum _GuardChoice { synced, discard }

/// Sign-out is blocked while the signed-in user has actions in the outbox:
/// once signed out they could only be sent by signing back in as the same
/// user. Resolves `true` when the caller may sign out: there was nothing
/// waiting, "Sync now" emptied the outbox, or the user discarded it (after
/// a second confirmation). `false` on Cancel.
Future<bool> confirmSignOutWithPending(BuildContext context) async {
  final cubit = context.read<SyncCubit>();
  if (cubit.state.entries.isEmpty) return true;
  final choice = await showDialog<_GuardChoice>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const SignOutBlockedDialog(),
    ),
  );
  if (choice == _GuardChoice.synced) return true;
  if (choice != _GuardChoice.discard || !context.mounted) return false;
  final count = cubit.state.entries.length;
  final sure = await showAppConfirmDialog(
    context: context,
    title: 'Discard ${_changes(count)}?',
    message:
        'They are deleted from this device and never reach the server. '
        'This cannot be undone.',
    confirmLabel: 'Discard and sign out',
    destructive: true,
  );
  if (!sure) return false;
  await cubit.discardAll();
  return true;
}

String _changes(int count) => count == 1 ? '1 change' : '$count changes';

/// "N changes haven't synced": Sync now (when the cloud is reachable),
/// Discard and sign out, or Cancel. Closes by itself, as synced, once the
/// outbox is empty.
class SignOutBlockedDialog extends StatelessWidget {
  const SignOutBlockedDialog({super.key});

  static const String title = "Changes haven't synced";

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncCubit, SyncState>(
      listenWhen: (p, c) => p.entries.isNotEmpty && c.entries.isEmpty,
      listener: (context, _) => Navigator.of(context).pop(_GuardChoice.synced),
      builder: (context, state) {
        final textTheme = Theme.of(context).textTheme;
        final status = state.status;
        final count = state.entries.length;
        final failed = state.failed.length;
        return AlertDialog(
          title: const Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_changes(count)} ${count == 1 ? "hasn't" : "haven't"} "
                'synced yet. Sync before signing out, or they stay on this '
                'device until you sign in again with this account.',
                style: textTheme.bodyMedium,
              ),
              if (failed > 0) ...[
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  '$failed ${failed == 1 ? 'was' : 'were'} refused by the '
                  'server: review ${failed == 1 ? 'it' : 'them'} in '
                  'Settings › Sync.',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ],
              if (!status.canSync) ...[
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  status.syncEnabled
                      ? "You're offline. Connect to sync now."
                      : 'Cloud sync is off. Turn it on to sync now.',
                  style: textTheme.bodySmall,
                ),
              ],
              if (status.syncing) ...[
                SizedBox(height: AppSpacing.md.h),
                const LinearProgressIndicator(),
              ],
            ],
          ),
          actionsOverflowButtonSpacing: AppSpacing.xs.h,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.error,
              ),
              onPressed: () => Navigator.of(context).pop(_GuardChoice.discard),
              child: const Text('Discard and sign out'),
            ),
            FilledButton(
              onPressed: status.canSync && !status.syncing
                  ? () => unawaited(context.read<SyncCubit>().syncNow())
                  : null,
              child: const Text('Sync now'),
            ),
          ],
        );
      },
    );
  }
}
