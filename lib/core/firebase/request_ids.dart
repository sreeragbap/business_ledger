import 'package:uuid/uuid.dart';

/// Client-generated idempotency keys for callables.
///
/// Generate one per user *intent* (one tap of "Record payment") and reuse it
/// for every retry of that intent: the server applies a `requestId` at most
/// once and returns the original result on a replay.
abstract final class RequestIds {
  /// What the functions accept (`functions/src/schemas.ts`).
  static final RegExp pattern = RegExp(r'^[A-Za-z0-9_-]{8,64}$');

  static const Uuid _uuid = Uuid();

  /// A v4 UUID without dashes: 32 hex characters.
  static String next() => _uuid.v4().replaceAll('-', '');
}
