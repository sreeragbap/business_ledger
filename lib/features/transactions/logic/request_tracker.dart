import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/firebase/request_ids.dart';

/// Holds the `requestId` of the one financial action a cubit has in flight,
/// so a retry of the **same** action (same key) reuses it and the server
/// returns the first result instead of applying the action twice
/// (FUNCTIONS_API, ARCHITECTURE §5 invariant 7).
///
/// The id is dropped on success and on a definitive refusal (a violation, a
/// conflict, a validation error): the outcome is known, and the next attempt
/// is a new action. It is kept only when the outcome is unknown.
class RequestTracker {
  RequestTracker([String Function()? next]) : _next = next ?? RequestIds.next;

  final String Function() _next;
  String? _key;
  String? _id;

  /// Whether [key] is the action whose outcome is still unknown.
  bool isPending(String key) => _key == key && _id != null;

  /// The id for the action identified by [key].
  String idFor(String key) {
    if (isPending(key)) return _id!;
    _key = key;
    return _id = _next();
  }

  /// Records how the action ended: `null` for success.
  void settle(AppException? error) {
    if (error != null && mayHaveLanded(error)) return;
    _key = null;
    _id = null;
  }

  /// The request may have reached the server (or never left): a retry must
  /// reuse the id.
  static bool mayHaveLanded(AppException error) =>
      error.kind == AppErrorKind.timeout ||
      error.kind == AppErrorKind.offline ||
      error.kind == AppErrorKind.unknown;
}
