import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

/// Whether the device has a network interface up.
///
/// Drives the offline banner and gates financial callables, which are refused
/// offline rather than queued (`docs/ARCHITECTURE.md` §2, Offline behaviour).
/// An interface being up does not prove the backend is reachable; a callable
/// that still fails comes back as `AppErrorKind.offline` from the server path.
@lazySingleton
class ConnectivityService {
  ConnectivityService(this._connectivity) {
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
    unawaited(refresh());
  }

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Optimistic until the first check lands: a cold start should not flash
  /// the offline banner.
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  /// Emits the current value first, then each change.
  Stream<bool> get onlineChanges async* {
    yield _isOnline;
    yield* _controller.stream;
  }

  /// Re-reads the platform state. Callers about to make a financial call use
  /// this rather than trusting a possibly stale [isOnline].
  Future<bool> refresh() async {
    try {
      _update(await _connectivity.checkConnectivity());
    } catch (_) {
      // A plugin failure must not lock the user out; keep the last answer.
    }
    return _isOnline;
  }

  static bool isOnlineFrom(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  void _update(List<ConnectivityResult> results) {
    final online = isOnlineFrom(results);
    if (online == _isOnline) return;
    _isOnline = online;
    _controller.add(online);
  }

  @disposeMethod
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
