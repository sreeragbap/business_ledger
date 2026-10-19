import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/supabase/remote_tables.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:injectable/injectable.dart';

/// Sends one outbox entry to the backend. The engine decides when; this
/// decides how. An interface so tests can fake the backend.
// ignore: one_member_abstracts
abstract class OutboxExecutor {
  const OutboxExecutor();

  /// Replays [entry] once. Never throws.
  Future<AppResult<void>> run(OutboxEntry entry);
}

@LazySingleton(as: OutboxExecutor)
class SupabaseOutboxExecutor extends OutboxExecutor {
  const SupabaseOutboxExecutor(this._rpc, this._tables);

  final RpcClient _rpc;
  final RemoteTables _tables;

  /// What a refused row update says. PostgREST answers an UPDATE that row
  /// level security filters out with "0 rows", not an error.
  static const AppException updateRefused = AppException(
    kind: AppErrorKind.permissionDenied,
    code: 'permission-denied',
    message:
        'The server refused this change: you may not have permission, or '
        'the record changed (e.g. a draft that was confirmed meanwhile).',
  );

  @override
  Future<AppResult<void>> run(OutboxEntry entry) async {
    // The engine has already checked connectivity and the sync switch.
    if (!entry.isRowWrite) {
      final result = await _rpc.call(
        entry.callable,
        entry.replayPayload,
        requiresOnline: false,
      );
      return result.map((_) {});
    }
    final table = entry.table;
    if (table == null) {
      return const Failure(
        AppException(
          kind: AppErrorKind.validation,
          code: 'invalid-argument',
          message: 'This queued change is unreadable. Discard it.',
        ),
      );
    }
    try {
      if (entry.kind == OutboxKind.upsert) {
        await _tables.upsert(table.name, entry.rows);
        return const Success(null);
      }
      for (final update in entry.updates) {
        final changed = await _tables.update(
          table.name,
          update.match,
          update.values,
        );
        if (changed == 0) return const Failure(updateRefused);
      }
      return const Success(null);
    } catch (error) {
      return Failure(AppException.from(error));
    }
  }
}
