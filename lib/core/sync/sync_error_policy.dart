import 'package:business_ledger/core/domain/app_exception.dart';

/// How the sync engine treats a failed replay.
abstract final class SyncErrorPolicy {
  /// Firebase codes that say "not now" rather than "no".
  static const Set<String> transientCodes = {
    'unavailable',
    'deadline-exceeded',
    'internal',
    'resource-exhausted',
    'network-request-failed',
    'retry-limit-exceeded',
    'unknown',
    'cancelled',
    'canceled',
  };

  /// Worth retrying later with the same requestId: the network, a timeout,
  /// an overloaded or crashed server. Everything else (invalid-argument,
  /// failed-precondition, permission-denied, not-found, already-exists,
  /// aborted, unauthenticated) is the server's answer and needs the user.
  static bool isTransient(AppException error) {
    final code = error.code;
    if (code != null && transientCodes.contains(code)) return true;
    return switch (error.kind) {
      AppErrorKind.offline ||
      AppErrorKind.timeout ||
      AppErrorKind.cancelled => true,
      // No code at all: a client-side surprise, not a server refusal.
      AppErrorKind.unknown => code == null || transientCodes.contains(code),
      _ => false,
    };
  }

  /// The network itself is down: stop the pass, other entries would fail
  /// the same way.
  static bool isNetworkDown(AppException error) =>
      error.kind == AppErrorKind.offline;

  static const String conflictMessage =
      'Changed by someone else — review and retry.';

  /// What the failed entry says. A conflict on replay means another device
  /// changed the transaction since the action was queued.
  static String messageFor(AppException error) =>
      error.isConflict ? conflictMessage : error.message;

  static const Duration minBackoff = Duration(seconds: 5);
  static const Duration maxBackoff = Duration(minutes: 5);

  /// 5 s, 10 s, 20 s … capped at 5 min, for the [attempts]th failure.
  static Duration backoff(int attempts) {
    final exponent = (attempts - 1).clamp(0, 16);
    final delay = minBackoff * (1 << exponent);
    return delay > maxBackoff ? maxBackoff : delay;
  }
}
