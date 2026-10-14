import 'dart:async';

import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Why an operation failed, in terms the UI can branch on without reading
/// Firebase error codes.
enum AppErrorKind {
  /// No connection, or the backend could not be reached. Firestore reads keep
  /// working from cache; financial callables are refused.
  offline,

  /// The request reached the server but the outcome is unknown. Retrying with
  /// the same `requestId` is safe: the server returns the original result.
  timeout,

  /// No signed-in user, or the session expired.
  unauthenticated,

  /// Signed in, but not a member of the business or lacking the role.
  permissionDenied,

  notFound,

  /// Someone else changed the record first (`expectedVersion` mismatch, or a
  /// contended transaction). The client reloads and lets the user retry.
  conflict,

  /// A ledger invariant refused the change; see [AppException.violation].
  violation,

  /// Input was rejected; see [AppException.field].
  validation,

  /// The record is referenced and cannot be removed (a category in use).
  inUse,

  /// A `requestId` was replayed with different input.
  requestReused,

  alreadyExists,

  /// The user dismissed a sheet or prompt. Not an error to show.
  cancelled,

  unknown,
}

/// The machine-readable cause a callable puts in `details.reason`
/// (`functions/src/lib/errors.ts`).
enum AppErrorReason {
  violation('violation'),
  conflict('conflict'),
  validation('validation'),
  notMember('notMember'),
  role('role'),
  notFound('notFound'),
  inUse('inUse'),
  requestReused('requestReused');

  const AppErrorReason(this.key);
  final String key;

  static AppErrorReason? fromKey(Object? key) {
    for (final reason in values) {
      if (reason.key == key) return reason;
    }
    return null;
  }
}

/// Every failure a repository returns, whatever produced it.
///
/// [message] is always safe to show the user. Server messages are used for
/// callable errors that carry a `reason` (the functions write them for the
/// user); everything else gets wording from here, because raw Firebase
/// messages are written for developers.
class AppException extends Equatable implements Exception {
  const AppException({
    required this.kind,
    required this.message,
    this.code,
    this.reason,
    this.violation,
    this.field,
    this.cause,
  });

  /// Dispatches on the runtime type. Subtypes first: both
  /// [FirebaseFunctionsException] and [FirebaseAuthException] are
  /// [FirebaseException]s.
  factory AppException.from(Object error) => switch (error) {
    final AppException e => e,
    final FirebaseFunctionsException e => AppException.fromFunctions(e),
    final FirebaseAuthException e => AppException.fromAuth(e),
    final FirebaseException e => AppException.fromFirebase(e),
    TimeoutException() => const AppException(
      kind: AppErrorKind.timeout,
      message: _timeoutMessage,
    ),
    _ => AppException.unknown(error),
  };

  /// A Firestore or Storage error.
  factory AppException.fromFirebase(FirebaseException error) {
    final code = normaliseCode(error.code);
    final kind = _kindForCode(code);
    return AppException(
      kind: kind,
      message: _messageFor(kind),
      code: code,
      cause: error.message,
    );
  }

  /// A callable error. `details` is `{reason, violation?, field?}` when the
  /// function raised it deliberately; absent for crashes and transport
  /// failures.
  factory AppException.fromFunctions(FirebaseFunctionsException error) {
    final code = normaliseCode(error.code);
    final details = _asMap(error.details);
    final reason = AppErrorReason.fromKey(details['reason']);
    final violation = _violationFrom(details['violation']);
    final field = details['field'];

    final kind = switch (reason) {
      AppErrorReason.violation => AppErrorKind.violation,
      AppErrorReason.conflict => AppErrorKind.conflict,
      AppErrorReason.validation => AppErrorKind.validation,
      AppErrorReason.notMember ||
      AppErrorReason.role => AppErrorKind.permissionDenied,
      AppErrorReason.notFound => AppErrorKind.notFound,
      AppErrorReason.inUse => AppErrorKind.inUse,
      AppErrorReason.requestReused => AppErrorKind.requestReused,
      null => _kindForCode(code),
    };

    // A deliberate server error's message is written for the user. Without a
    // reason it may be an internal crash text, so it is not trusted.
    final serverMessage = error.message?.trim() ?? '';
    final message = violation != null
        ? violation.message
        : reason != null && serverMessage.isNotEmpty
        ? serverMessage
        : _messageFor(kind);

    return AppException(
      kind: kind,
      message: message,
      code: code,
      reason: reason,
      violation: violation,
      field: field is String && field.isNotEmpty ? field : null,
      cause: error.message,
    );
  }

  /// A Firebase Auth error, including the provider sheet being dismissed.
  factory AppException.fromAuth(FirebaseAuthException error) {
    final code = normaliseCode(error.code);
    final (kind, message) = switch (code) {
      'network-request-failed' => (
        AppErrorKind.offline,
        _messageFor(AppErrorKind.offline),
      ),
      'canceled' ||
      'cancelled' ||
      'web-context-canceled' ||
      'popup-closed-by-user' => (AppErrorKind.cancelled, _cancelledMessage),
      'user-disabled' => (
        AppErrorKind.permissionDenied,
        'This account has been disabled.',
      ),
      'account-exists-with-different-credential' => (
        AppErrorKind.alreadyExists,
        'An account already exists with this email. Sign in with the '
            'method you used before.',
      ),
      'invalid-credential' || 'user-token-expired' || 'user-not-found' => (
        AppErrorKind.unauthenticated,
        'Your sign-in could not be verified. Please try again.',
      ),
      'too-many-requests' => (
        AppErrorKind.unknown,
        'Too many attempts. Please wait a moment and try again.',
      ),
      _ => (
        _kindForCode(code),
        _messageFor(_kindForCode(code)),
      ),
    };
    return AppException(
      kind: kind,
      message: message,
      code: code,
      cause: error.message,
    );
  }

  factory AppException.unknown([Object? error]) => AppException(
    kind: AppErrorKind.unknown,
    message: _messageFor(AppErrorKind.unknown),
    cause: error?.toString(),
  );

  /// Raised before a request is made, when the device is known to be offline.
  const AppException.offline()
    : kind = AppErrorKind.offline,
      message = _offlineMessage,
      code = null,
      reason = null,
      violation = null,
      field = null,
      cause = null;

  /// The user dismissed a sign-in sheet or system prompt.
  const AppException.cancelled()
    : kind = AppErrorKind.cancelled,
      message = _cancelledMessage,
      code = null,
      reason = null,
      violation = null,
      field = null,
      cause = null;

  final AppErrorKind kind;

  /// User-safe text.
  final String message;

  /// The Firebase code, normalised (`aborted`, `permission-denied`…).
  final String? code;

  final AppErrorReason? reason;

  /// Which ledger rule refused the change, when [kind] is
  /// [AppErrorKind.violation].
  final LedgerViolation? violation;

  /// The request field the server rejected, for inline form errors.
  final String? field;

  /// The developer-facing detail, for logs and Crashlytics. Never shown.
  final String? cause;

  bool get isOffline => kind == AppErrorKind.offline;
  bool get isConflict => kind == AppErrorKind.conflict;
  bool get isCancelled => kind == AppErrorKind.cancelled;

  /// `ABORTED`, `functions/aborted` and `aborted` all become `aborted`;
  /// `FAILED_PRECONDITION` becomes `failed-precondition`. Platforms disagree
  /// on spelling, the meaning does not.
  static String normaliseCode(String code) {
    final bare = code.contains('/') ? code.split('/').last : code;
    return bare.trim().toLowerCase().replaceAll('_', '-');
  }

  static AppErrorKind _kindForCode(String code) => switch (code) {
    'unavailable' || 'network-request-failed' => AppErrorKind.offline,
    'deadline-exceeded' => AppErrorKind.timeout,
    'unauthenticated' => AppErrorKind.unauthenticated,
    'permission-denied' || 'unauthorized' => AppErrorKind.permissionDenied,
    'not-found' || 'object-not-found' => AppErrorKind.notFound,
    // Firestore raises `aborted` for contended transactions too; either way
    // the remedy is the same: reload and retry.
    'aborted' => AppErrorKind.conflict,
    'invalid-argument' => AppErrorKind.validation,
    'already-exists' => AppErrorKind.alreadyExists,
    'cancelled' || 'canceled' => AppErrorKind.cancelled,
    _ => AppErrorKind.unknown,
  };

  static const String _offlineMessage =
      "You're offline. Connect to the internet and try again.";
  static const String _timeoutMessage =
      'The request took too long. Check your connection and try again.';
  static const String _cancelledMessage = 'Cancelled.';

  static String _messageFor(AppErrorKind kind) => switch (kind) {
    AppErrorKind.offline => _offlineMessage,
    AppErrorKind.timeout => _timeoutMessage,
    AppErrorKind.unauthenticated => 'Your session has ended. Sign in again.',
    AppErrorKind.permissionDenied =>
      "You don't have permission to do that in this business.",
    AppErrorKind.notFound => 'That record no longer exists.',
    AppErrorKind.conflict =>
      'This record was changed by someone else. Reload and try again.',
    AppErrorKind.violation => 'That change is not allowed.',
    AppErrorKind.validation => 'Some details are not valid. Check and retry.',
    AppErrorKind.inUse => 'This is in use and cannot be removed.',
    AppErrorKind.requestReused =>
      'This request was already used for something else. Try again.',
    AppErrorKind.alreadyExists => 'That already exists.',
    AppErrorKind.cancelled => _cancelledMessage,
    AppErrorKind.unknown => 'Something went wrong. Please try again.',
  };

  static Map<String, Object?> _asMap(Object? details) {
    if (details is Map) {
      return details.map((key, value) => MapEntry('$key', value));
    }
    return const {};
  }

  static LedgerViolation? _violationFrom(Object? key) {
    for (final violation in LedgerViolation.values) {
      if (violation.name == key) return violation;
    }
    return null;
  }

  @override
  List<Object?> get props => [kind, message, code, reason, violation, field];

  @override
  String toString() =>
      'AppException(${kind.name}, code: $code, reason: ${reason?.key}, '
      'message: $message)';
}
