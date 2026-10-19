import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';

/// A business's customers and suppliers. Local-first, offline-friendly
/// writes; archived rather than deleted.
///
/// For the transaction form: [watchParties], filter with
/// `!archived && kind.matches(...)` and `matchesQuery`, and store `partyId`
/// plus a `partyName` snapshot.
abstract class PartyRepository {
  const PartyRepository();

  /// Every party, archived included, ordered by name. Live.
  Stream<AppResult<List<Party>>> watchParties(String businessId);

  Future<AppResult<Party?>> getParty(String businessId, String id);

  /// Creates [party] (its `id` is ignored) and returns the new id, usable at
  /// once (e.g. "add a new customer" from inside a transaction form).
  Future<AppResult<String>> create(String businessId, Party party);

  Future<AppResult<void>> update(String businessId, Party party);

  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  });
}
