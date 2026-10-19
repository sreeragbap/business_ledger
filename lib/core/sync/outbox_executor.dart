import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
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
class FirebaseOutboxExecutor extends OutboxExecutor {
  const FirebaseOutboxExecutor(this._callable);

  final CallableClient _callable;

  @override
  Future<AppResult<void>> run(OutboxEntry entry) async {
    // The engine has already checked connectivity and the sync switch.
    final result = await _callable.call(
      entry.callable,
      entry.replayPayload,
      requiresOnline: false,
    );
    return result.map((_) {});
  }
}
