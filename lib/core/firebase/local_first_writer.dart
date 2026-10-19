import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/pending_writes_tracker.dart';
import 'package:injectable/injectable.dart';

/// Commits configuration writes (categories, fields, parties, projects,
/// business settings) the offline-first way.
///
/// A Firestore `set()` / `update()` / `batch.commit()` future completes only
/// when the **server** acknowledges it, yet the write is applied to the local
/// cache, and every listener sees it, the moment it is issued. Awaiting the
/// future offline would leave a spinner up until the device reconnects.
///
/// So:
/// * offline, or with Cloud sync off, the write is handed to Firestore's
///   queue and reported as a success at once;
/// * online, the server is given [ackWait] to answer, so a rules rejection
///   still surfaces inline on the form that caused it;
/// * a rejection that arrives after the hand-off (sync on reconnect) is
///   published on [lateFailures], which the app shows as a snack bar.
///
/// Each hand-off is counted in [PendingWritesTracker] until the server
/// answers, for the sync status.
@lazySingleton
class LocalFirstWriter {
  LocalFirstWriter(this._availability, this._tracker);

  final CloudAvailability _availability;
  final PendingWritesTracker _tracker;

  /// How long an online write may take before it is treated as queued.
  static const Duration ackWait = Duration(seconds: 4);

  final StreamController<AppException> _late =
      StreamController<AppException>.broadcast();

  /// Writes that failed after the UI was already told they succeeded.
  Stream<AppException> get lateFailures => _late.stream;

  Future<AppResult<void>> commit(Future<void> Function() write) async {
    final Future<void> pending;
    try {
      pending = write();
    } catch (error) {
      // Thrown synchronously: a bad path or argument, never queued.
      return Failure(AppException.from(error));
    }

    var handedOff = false;
    var settled = false;
    void handOff() {
      handedOff = true;
      if (!settled) _tracker.begin();
    }

    // Always attached, so a late error is never "unhandled".
    unawaited(
      pending
          .then<void>(
            (_) {},
            onError: (Object error) {
              if (handedOff && !_late.isClosed) {
                _late.add(AppException.from(error));
              }
            },
          )
          .whenComplete(() {
            settled = true;
            if (handedOff) _tracker.end();
          }),
    );

    if (!_availability.isOnline) {
      handOff();
      return const Success(null);
    }
    try {
      await pending.timeout(ackWait);
      return const Success(null);
    } on TimeoutException {
      handOff();
      return const Success(null);
    } catch (error) {
      return Failure(AppException.from(error));
    }
  }

  @disposeMethod
  Future<void> dispose() => _late.close();
}
