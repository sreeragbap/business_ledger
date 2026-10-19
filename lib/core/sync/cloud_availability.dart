import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:business_ledger/core/sync/sync_identity.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Whether the app may talk to the backend right now: the device is online,
/// Cloud sync is on **and** someone is signed in (Supabase accepts nothing
/// without a Firebase ID token).
///
/// Everything that used to ask "am I online?" before reaching for the
/// server (RPCs, pushes, pulls) asks this instead, so turning sync off
/// behaves exactly like being offline. Same member names as
/// [ConnectivityService] on purpose.
@lazySingleton
class CloudAvailability {
  CloudAvailability(this._connectivity, this._settings, this._identity);

  final ConnectivityService _connectivity;
  final SyncSettings _settings;
  final SyncIdentity _identity;

  bool get deviceOnline => _connectivity.isOnline;
  bool get syncEnabled => _settings.enabled;
  bool get signedIn => _identity.uid != null;

  /// Online, sync on and signed in.
  bool get isOnline => deviceOnline && syncEnabled && signedIn;

  /// The current value first, then each change.
  Stream<bool> get onlineChanges =>
      Rx.combineLatest3<bool, bool, String?, bool>(
        _connectivity.onlineChanges,
        _settings.enabledChanges,
        _identity.uidChanges,
        (online, enabled, uid) => online && enabled && uid != null,
      ).distinct();

  /// Re-reads the platform state, then answers [isOnline].
  Future<bool> refresh() async {
    final online = await _connectivity.refresh();
    return online && syncEnabled && signedIn;
  }

  static const AppException signedOut = AppException(
    kind: AppErrorKind.unauthenticated,
    message: 'Your session has ended. Sign in again.',
  );

  /// Why the backend cannot be reached, for actions that cannot wait.
  AppException get unavailableError => !signedIn
      ? signedOut
      : syncEnabled
      ? const AppException.offline()
      : const AppException.syncOff();
}
