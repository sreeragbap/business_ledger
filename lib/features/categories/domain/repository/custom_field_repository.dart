import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';

/// A business's custom fields. Direct, offline-friendly Firestore writes;
/// never deleted, only archived.
///
/// For the transaction form: for a chosen category, show
/// `category.fieldIds` resolved against [watchFields] (skipping archived
/// ones and ids that no longer resolve), in that order.
abstract class CustomFieldRepository {
  const CustomFieldRepository();

  /// Every field, archived included, ordered by `sortOrder`. Live.
  Stream<AppResult<List<CustomField>>> watchFields(String businessId);

  /// Creates [field] (its `id` is ignored) and returns the new id.
  Future<AppResult<String>> create(String businessId, CustomField field);

  Future<AppResult<void>> update(String businessId, CustomField field);

  /// Applies `{fieldId: sortOrder}` in one batch.
  Future<AppResult<void>> reorder(String businessId, Map<String, int> orders);

  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
    int? sortOrder,
  });
}
