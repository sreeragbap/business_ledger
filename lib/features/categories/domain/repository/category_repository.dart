import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';

/// A business's categories.
///
/// Writes are local-first (offline-friendly: they succeed once stored on the
/// device and queued, see `LocalWriter`), except [delete], which is an RPC
/// because only the server can prove nothing references it.
///
/// For the transaction form: use [watchCategories], offer the ones that are
/// not archived and whose `kind.allows(direction)`, and resolve a stored
/// `categoryId` against the full list (archived included) — or [getCategory]
/// for a single lookup.
abstract class CategoryRepository {
  const CategoryRepository();

  /// Every category, archived included, ordered by `sortOrder`. Live.
  Stream<AppResult<List<Category>>> watchCategories(String businessId);

  /// One category by id (archived included); `null` when deleted.
  Future<AppResult<Category?>> getCategory(String businessId, String id);

  /// Creates [category] (its `id` is ignored) and returns the new id.
  Future<AppResult<String>> create(String businessId, Category category);

  Future<AppResult<void>> update(String businessId, Category category);

  /// Applies `{categoryId: sortOrder}` in one batch.
  Future<AppResult<void>> reorder(String businessId, Map<String, int> orders);

  /// [sortOrder], when given, is written too (unarchived items go last).
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
    int? sortOrder,
  });

  /// `delete_category` RPC. Online only. Fails with
  /// `AppErrorKind.inUse` when any transaction references the category; the
  /// remedy is to archive it.
  Future<AppResult<void>> delete(String businessId, String id);
}
