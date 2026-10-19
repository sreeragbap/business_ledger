import 'package:uuid/uuid.dart';

/// Client-generated ids: idempotency keys for RPCs, and the uuid primary
/// keys of rows created on the device (drafts, configuration).
///
/// Generate one per user *intent* (one tap of "Record payment") and reuse it
/// for every retry of that intent: the server applies a `requestId` at most
/// once and returns the original result on a replay.
abstract final class RequestIds {
  /// What the RPCs accept (`app.arg_request_id`).
  static final RegExp pattern = RegExp(r'^[A-Za-z0-9_-]{8,64}$');

  static const Uuid _uuid = Uuid();

  /// A v4 UUID without dashes: 32 hex characters.
  static String next() => _uuid.v4().replaceAll('-', '');

  /// A v4 UUID with dashes: a new row's id (`uuid` columns).
  static String rowId() => _uuid.v4();
}
