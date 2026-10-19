import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls one Postgres function through PostgREST (`POST /rest/v1/rpc/<fn>`).
/// An interface the app owns, so tests fake the backend.
// ignore: one_member_abstracts
abstract class RemoteRpc {
  const RemoteRpc();

  /// The function's JSON result. Throws what the client throws.
  Future<Object?> call(String function, Map<String, Object?> params);
}

@LazySingleton(as: RemoteRpc)
class SupabaseRemoteRpc extends RemoteRpc {
  const SupabaseRemoteRpc(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> call(String function, Map<String, Object?> params) =>
      _client.rpc<Object?>(function, params: params);
}
