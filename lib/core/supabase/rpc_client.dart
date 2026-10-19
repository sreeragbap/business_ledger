import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/supabase/remote_rpc.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:injectable/injectable.dart';

/// The one way the app calls the server's Postgres functions (RPCs).
///
/// Callers speak the old callable vocabulary: a camelCase action name
/// (`recordSettlement`) and a camelCase payload (`{businessId, requestId,
/// amountMinor…}`), which is also what the outbox stores. This maps both to
/// the RPC (`record_settlement`, `{p_business_id, p_request_id,
/// p_amount_minor…}`, `supabase/README.md` RPCs). Results keep the callable
/// result keys, so parsing is unchanged.
///
/// It adds nothing to the payload: callers put a `requestId` from
/// `RequestIds.next()` in it, because only they know which taps are retries
/// of the same intent.
///
/// Money actions (confirm, settle, edit, cancel) do not call this directly:
/// they go through `SyncQueue`, which queues them in the outbox when the
/// cloud is unavailable. Everything else (create business, members, delete
/// category, issue document) cannot wait and is refused up front.
@lazySingleton
class RpcClient {
  RpcClient(this._remote, this._availability);

  final RemoteRpc _remote;
  final CloudAvailability _availability;

  /// Generous: a confirm with stats and audit writes is several statements
  /// under row locks, on a mobile link.
  static const Duration timeout = Duration(seconds: 30);

  /// The callables this replaces, and their RPCs.
  static const Map<String, String> functions = {
    'createBusiness': 'create_business',
    'addMember': 'add_member',
    'updateMemberRole': 'update_member_role',
    'removeMember': 'remove_member',
    'deleteCategory': 'delete_category',
    'confirmTransaction': 'confirm_transaction',
    'editConfirmedTransaction': 'edit_confirmed_transaction',
    'cancelTransaction': 'cancel_transaction',
    'recordSettlement': 'record_settlement',
    'issueDocument': 'issue_document',
  };

  /// `recordSettlement` → `record_settlement`.
  static String functionFor(String action) =>
      functions[action] ??
      (throw ArgumentError.value(action, 'action', 'Unknown RPC'));

  /// `{businessId: …, amountMinor: …}` → `{p_business_id: …,
  /// p_amount_minor: …}`. Only top-level keys change: a JSON argument
  /// (`changes`) keeps its camelCase keys, as the RPC expects. A `null`
  /// argument is left out, so the function's default applies.
  static Map<String, Object?> paramsFor(Map<String, Object?> payload) => {
    for (final entry in payload.entries)
      if (entry.value != null) 'p_${RowKeys.snake(entry.key)}': entry.value,
  };

  /// Calls [action] with [data].
  ///
  /// With [requiresOnline] (the default) the call is refused up front when
  /// the device is offline, Cloud sync is off or nobody is signed in, rather
  /// than sent to fail slowly. `SyncQueue` and the sync engine pass `false`:
  /// they have already checked.
  Future<AppResult<Map<String, dynamic>>> call(
    String action,
    Map<String, Object?> data, {
    bool requiresOnline = true,
  }) async {
    if (requiresOnline && !await _availability.refresh()) {
      return Failure(_availability.unavailableError);
    }
    return AppResult.guard(() async {
      final result = await _remote
          .call(functionFor(action), paramsFor(data))
          .timeout(timeout);
      return asJsonMap(result);
    });
  }

  /// RPC results are JSON objects; models expect `Map<String, dynamic>`.
  static Map<String, dynamic> asJsonMap(Object? value) {
    if (value == null) return <String, dynamic>{};
    if (value is! Map) {
      throw FormatException('Expected a JSON object from the RPC, got $value');
    }
    return value.map((key, inner) => MapEntry('$key', _deep(inner)));
  }

  static Object? _deep(Object? value) => switch (value) {
    final Map<Object?, Object?> map => asJsonMap(map),
    final List<Object?> list => list.map(_deep).toList(),
    _ => value,
  };
}
