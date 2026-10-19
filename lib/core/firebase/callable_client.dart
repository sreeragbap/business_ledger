import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

/// The one way the app calls Cloud Functions.
///
/// It adds nothing to the payload: callers put a `requestId` from
/// `RequestIds.next()` in the payload themselves, because only the caller knows
/// which taps are retries of the same intent.
///
/// Money actions (confirm, settle, edit, cancel) do not call this directly
/// any more: they go through `SyncQueue`, which queues them in the outbox
/// when the cloud is unavailable. Everything else (create business, members,
/// delete category, issue document) cannot wait and is refused up front.
@lazySingleton
class CallableClient {
  CallableClient(this._functions, this._availability);

  final FirebaseFunctions _functions;
  final CloudAvailability _availability;

  /// Generous: a confirm with stats and audit writes is a multi-document
  /// transaction, and a cold start in `asia-south1` adds seconds.
  static const Duration timeout = Duration(seconds: 30);

  /// Calls [name] with [data].
  ///
  /// With [requiresOnline] (the default) the call is refused up front when
  /// the device is offline or Cloud sync is off, rather than handed to the
  /// SDK to fail slowly (or, with sync off, to quietly go out anyway: the
  /// switch only stops Firestore, not Functions). `SyncQueue` and the sync
  /// engine pass `false`: they have already checked.
  Future<AppResult<Map<String, dynamic>>> call(
    String name,
    Map<String, Object?> data, {
    bool requiresOnline = true,
  }) async {
    if (requiresOnline && !await _availability.refresh()) {
      return Failure(_availability.unavailableError);
    }
    return AppResult.guard(() async {
      final result = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
          .call<Object?>(data);
      return asJsonMap(result.data);
    });
  }

  /// Platform channels hand back `Map<Object?, Object?>` all the way down;
  /// models expect `Map<String, dynamic>`.
  static Map<String, dynamic> asJsonMap(Object? value) {
    if (value == null) return <String, dynamic>{};
    if (value is! Map) {
      throw FormatException('Expected a map from the callable, got $value');
    }
    return value.map((key, inner) => MapEntry('$key', _deep(inner)));
  }

  static Object? _deep(Object? value) => switch (value) {
    final Map<Object?, Object?> map => asJsonMap(map),
    final List<Object?> list => list.map(_deep).toList(),
    _ => value,
  };
}
