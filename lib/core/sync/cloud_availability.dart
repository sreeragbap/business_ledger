import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Whether the app may talk to the backend right now: the device is online
/// **and** Cloud sync is on.
///
/// Everything that used to ask "am I online?" before reaching for the
/// server (callables, uploads, waiting for a write to be acknowledged) asks
/// this instead, so turning sync off behaves exactly like being offline.
/// Same member names as [ConnectivityService] on purpose.
@lazySingleton
class CloudAvailability {
  CloudAvailability(this._connectivity, this._settings);

  final ConnectivityService _connectivity;
  final SyncSettings _settings;

  bool get deviceOnline => _connectivity.isOnline;
  bool get syncEnabled => _settings.enabled;

  /// Online and sync on.
  bool get isOnline => deviceOnline && syncEnabled;

  /// The current value first, then each change.
  Stream<bool> get onlineChanges => Rx.combineLatest2<bool, bool, bool>(
    _connectivity.onlineChanges,
    _settings.enabledChanges,
    (online, enabled) => online && enabled,
  ).distinct();

  /// Re-reads the platform state, then answers [isOnline].
  Future<bool> refresh() async {
    final online = await _connectivity.refresh();
    return online && syncEnabled;
  }

  /// Why the backend cannot be reached, for actions that cannot wait.
  AppException get unavailableError =>
      syncEnabled ? const AppException.offline() : const AppException.syncOff();
}
