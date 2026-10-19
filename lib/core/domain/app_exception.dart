import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:business_ledger/core/ledger/ledger_math.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Why an operation failed, in terms the UI can branch on without reading
/// backend error codes.
enum AppErrorKind {
  /// No connection, or the backend could not be reached. Reads keep working
  /// from the on-device store; money actions are queued.
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

/// The machine-readable cause an RPC puts in `details.reason`
/// (`supabase/README.md`, Error contract).
enum AppErrorReason {
  violation('violation'),
  conflict('conflict'),
  validation('validation'),
  notMember('notMember'),
  role('role'),
  notFound('notFound'),
  inUse('inUse'),
  requestReused('requestReused'),

  /// A guard trigger refused a change to a column that never changes.
  immutable('immutable'),
  unauthenticated('unauthenticated');

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
/// RPC errors that carry a `reason` (the database writes them for the
/// user); everything else gets wording from here, because raw Postgres and
/// Firebase messages are written for developers.
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

  /// Dispatches on the runtime type. Subtypes first: a
  /// [FirebaseAuthException] is a [FirebaseException].
  factory AppException.from(Object error) => switch (error) {
    final AppException e => e,
    final PostgrestException e => AppException.fromPostgrest(e),
    final FirebaseAuthException e => AppException.fromAuth(e),
    final FirebaseException e => AppException.fromFirebase(e),
    TimeoutException() => const AppException(
      kind: AppErrorKind.timeout,
      message: _timeoutMessage,
    ),
    // The request never got an answer: no network, DNS, TLS, a dropped
    // connection. Safe to retry (money actions carry a request id).
    SocketException() ||
    HttpException() ||
    http.ClientException() => AppException(
      kind: AppErrorKind.offline,
      message: _offlineMessage,
      code: 'unavailable',
      cause: '$error',
    ),
    _ => AppException.unknown(error),
  };

  /// A PostgREST error: an RPC's deliberate refusal (SQLSTATE `PTnnn` with
  /// `details` = `{code, reason, violation?, field?}`, `supabase/README.md`
  /// Error contract), or a database / gateway error outside the contract.
  factory AppException.fromPostgrest(PostgrestException error) {
    final details = _asMap(_decodeDetails(error.details));
    final contractCode = details['code'];
    if (contractCode is String && contractCode.isNotEmpty) {
      return AppException._fromContract(
        code: normaliseCode(contractCode),
        details: details,
        serverMessage: error.message,
        cause: '${error.code}: ${error.message}',
      );
    }
    final sqlState = (error.code ?? '').trim().toUpperCase();
    final code = _codeForSqlState(sqlState);
    final kind = _kindForCode(code);
    return AppException(
      kind: kind,
      message: _messageFor(kind),
      code: code,
      cause: '$sqlState: ${error.message}',
    );
  }

  /// A Firebase error other than Auth (e.g. from `firebase_core`).
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

  /// An error that follows the RPC error contract: [code] is
  /// `details.code` (`failed-precondition`, `aborted`…), the rest comes from
  /// `details`.
  factory AppException._fromContract({
    required String code,
    required Map<String, Object?> details,
    required String serverMessage,
    String? cause,
  }) {
    final reason = AppErrorReason.fromKey(details['reason']);
    final violation = _violationFrom(details['violation']);
    final field = details['field'];

    final kind = switch (reason) {
      AppErrorReason.violation => AppErrorKind.violation,
      AppErrorReason.conflict => AppErrorKind.conflict,
      AppErrorReason.validation =>
        code == 'already-exists'
            ? AppErrorKind.alreadyExists
            : AppErrorKind.validation,
      AppErrorReason.notMember ||
      AppErrorReason.role ||
      AppErrorReason.immutable => AppErrorKind.permissionDenied,
      AppErrorReason.notFound => AppErrorKind.notFound,
      AppErrorReason.inUse => AppErrorKind.inUse,
      AppErrorReason.requestReused => AppErrorKind.requestReused,
      AppErrorReason.unauthenticated => AppErrorKind.unauthenticated,
      null => _kindForCode(code),
    };

    // A deliberate refusal's message is written for the user. Without a
    // reason it may be internal text, so it is not trusted.
    final trimmed = serverMessage.trim();
    final message = violation != null
        ? violation.message
        : reason != null && trimmed.isNotEmpty
        ? trimmed
        : _messageFor(kind);

    return AppException(
      kind: kind,
      message: message,
      code: code,
      reason: reason,
      violation: violation,
      field: field is String && field.isNotEmpty ? field : null,
      cause: cause,
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

  /// Raised before a request is made, when Cloud sync is switched off on
  /// this device. Same [kind] as [AppException.offline]: to the caller the
  /// backend is unreachable either way.
  const AppException.syncOff()
    : kind = AppErrorKind.offline,
      message = syncOffMessage,
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

  /// The error code, normalised (`aborted`, `permission-denied`…): the
  /// RPC contract's `details.code`, or one derived from the SQLSTATE.
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

  /// `ABORTED`, `auth/aborted` and `aborted` all become `aborted`;
  /// `FAILED_PRECONDITION` becomes `failed-precondition`. Sources disagree
  /// on spelling, the meaning does not.
  static String normaliseCode(String code) {
    final bare = code.contains('/') ? code.split('/').last : code;
    return bare.trim().toLowerCase().replaceAll('_', '-');
  }

  static AppErrorKind _kindForCode(String code) => switch (code) {
    'unavailable' || 'network-request-failed' => AppErrorKind.offline,
    'failed-precondition' => AppErrorKind.violation,
    'deadline-exceeded' => AppErrorKind.timeout,
    'unauthenticated' => AppErrorKind.unauthenticated,
    'permission-denied' => AppErrorKind.permissionDenied,
    'not-found' => AppErrorKind.notFound,
    // A stale `p_expected_version`: reload and retry.
    'aborted' => AppErrorKind.conflict,
    'invalid-argument' => AppErrorKind.validation,
    'already-exists' => AppErrorKind.alreadyExists,
    'cancelled' || 'canceled' => AppErrorKind.cancelled,
    _ => AppErrorKind.unknown,
  };

  static const String _offlineMessage =
      "You're offline. Connect to the internet and try again.";

  /// For actions that cannot be queued while sync is off.
  static const String syncOffMessage =
      'Cloud sync is off. This needs a connection and sync turned on '
      '(Settings › Sync).';
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

  /// SQLSTATEs and PostgREST codes outside the contract, as the normalised
  /// codes the rest of the app (and `SyncErrorPolicy`) understands.
  static String _codeForSqlState(String state) {
    switch (state) {
      // A PTnnn without the JSON detail (should not happen): its status.
      case 'PT400':
        return 'invalid-argument';
      case 'PT401':
        return 'unauthenticated';
      case 'PT403':
        return 'permission-denied';
      case 'PT404':
        return 'not-found';
      case 'PT409':
        return 'aborted';
      case 'PT412':
        return 'failed-precondition';
      case 'PT422':
        return 'already-exists';
      // Row level security / privileges on a direct table write.
      case '42501':
        return 'permission-denied';
      // JWT missing, expired or not accepted (PostgREST).
      case 'PGRST300' || 'PGRST301' || 'PGRST302' || 'PGRST303':
        return 'unauthenticated';
      // `.single()` found nothing.
      case 'PGRST116':
        return 'not-found';
    }
    // CHECK / NOT NULL / unique / bad input (23xxx, 22xxx): resending the
    // same row cannot succeed.
    if (state.startsWith('23') || state.startsWith('22')) {
      return 'invalid-argument';
    }
    // HTTP status codes (a gateway answering with a non-JSON body).
    final status = int.tryParse(state);
    if (status != null) {
      if (status == 401) return 'unauthenticated';
      if (status == 403) return 'permission-denied';
      if (status == 404) return 'not-found';
      if (status >= 500 || status == 408 || status == 429) return 'unavailable';
    }
    // Deadlock, serialization failure, statement timeout, connection or
    // resource trouble, anything unknown: the server's state did not
    // change; try again later.
    return 'internal';
  }

  static Object? _decodeDetails(Object? details) {
    if (details is! String) return details;
    final text = details.trim();
    if (!text.startsWith('{')) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

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
