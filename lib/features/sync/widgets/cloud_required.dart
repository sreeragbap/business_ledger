import 'package:business_ledger/features/sync/logic/sync_cubit/sync_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// For actions that cannot be queued (create business, members, delete
/// category, issue document): whether they can run now.
abstract final class CloudRequired {
  static const String reason = 'Needs a connection and sync turned on.';

  /// Online and Cloud sync on, rebuilding [context] on change. `true` where
  /// no [SyncCubit] is provided (isolated widget tests).
  static bool watch(BuildContext context) {
    try {
      return context.select<SyncCubit, bool>(
        (cubit) => cubit.state.status.canSync,
      );
    } on ProviderNotFoundException {
      return true;
    }
  }
}
