import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:business_ledger/core/sync/sync_status.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'sync_state.dart';

/// App-wide sync state for the banner and the Sync screen: the engine's
/// status, the signed-in user's outbox, and the user's controls (the Cloud
/// sync switch, "Sync now", retry and discard).
@lazySingleton
class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._engine, this._settings)
    : super(SyncState(status: _engine.status)) {
    _subscriptions
      ..add(
        _engine.statusChanges.listen(
          (status) => emit(state.copyWith(status: status)),
        ),
      )
      ..add(
        _engine.entries.listen(
          (entries) => emit(state.copyWith(entries: entries)),
        ),
      );
  }

  final SyncEngine _engine;
  final SyncSettings _settings;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Turns Cloud sync on or off on this device.
  Future<void> setEnabled({required bool enabled}) async {
    emit(state.copyWith(actionStatus: const Status.loading()));
    await _settings.setEnabled(value: enabled);
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: Status.success(
          message: enabled
              ? 'Cloud sync is on. Uploading what was waiting.'
              : 'Cloud sync is off. Changes stay on this device.',
        ),
      ),
    );
  }

  Future<void> syncNow() async {
    if (!state.status.canSync) {
      emit(
        state.copyWith(
          actionStatus: Status.failure(
            state.status.syncEnabled
                ? "You're offline. Changes will sync when you reconnect."
                : 'Turn Cloud sync on to upload.',
          ),
        ),
      );
      return;
    }
    await _engine.syncNow();
  }

  Future<void> retry(String id) async {
    await _engine.retry(id);
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: const Status.success(message: 'Trying again.'),
      ),
    );
  }

  /// Later entries for the same transaction, discarded along with [id].
  List<OutboxEntry> dependentsOf(String id) => _engine.dependentsOf(id);

  Future<void> discard(String id) async {
    final removed = await _engine.discard(id);
    if (isClosed) return;
    emit(
      state.copyWith(
        actionStatus: Status.success(
          message: removed.length > 1
              ? '${removed.length} actions discarded.'
              : 'Discarded.',
        ),
      ),
    );
  }

  /// Drops all of this user's waiting actions (before signing out).
  Future<int> discardAll() async {
    final removed = await _engine.discardAll();
    return removed.length;
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
