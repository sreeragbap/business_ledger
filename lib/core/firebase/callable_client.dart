import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/connectivity_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

/// The one way the app calls Cloud Functions.
///
/// It adds nothing to the payload: callers put a `requestId` from
/// `RequestIds.next()` in [data] themselves, because only the caller knows
/// which taps are retries of the same intent.
@lazySingleton
class CallableClient {
  CallableClient(this._functions, this._connectivity);

  final FirebaseFunctions _functions;
  final ConnectivityService _connectivity;

  /// Generous: a confirm with stats and audit writes is a multi-document
  /// transaction, and a cold start in `asia-south1` adds seconds.
  static const Duration timeout = Duration(seconds: 30);

  /// Calls [name] with [data].
  ///
  /// With [requiresOnline] (the default, for every financial operation) the
  /// call is refused up front when the device is offline, rather than handed
  /// to the SDK to fail slowly.
  Future<AppResult<Map<String, dynamic>>> call(
    String name,
    Map<String, dynamic> data, {
    bool requiresOnline = true,
  }) async {
    if (requiresOnline && !await _connectivity.refresh()) {
      return const Failure(AppException.offline());
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
