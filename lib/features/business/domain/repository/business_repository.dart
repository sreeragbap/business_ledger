import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/create_business_request.dart';

/// Businesses the signed-in user belongs to, and the user's last choice.
abstract class BusinessRepository {
  const BusinessRepository();

  /// Every business [uid] is a member of (archived included), sorted by
  /// name. Live.
  Stream<AppResult<List<Business>>> watchMyBusinesses(String uid);

  /// One business, live; `null` once it no longer exists.
  Stream<AppResult<Business?>> watchBusiness(String businessId);

  /// `createBusiness` callable. Online only. Returns the new business id.
  Future<AppResult<String>> createBusiness(CreateBusinessRequest request);

  /// Name, description, time zone and settings (admin+). Offline-friendly:
  /// succeeds once the write is queued locally.
  Future<AppResult<void>> updateDetails(
    String businessId, {
    required String name,
    required String description,
    required String timezone,
    required BusinessSettings settings,
  });

  /// Owner only.
  Future<AppResult<void>> setArchived(
    String businessId, {
    required bool archived,
  });

  /// The business [uid] last worked in: the on-device cache first, then
  /// `users/{uid}.lastBusinessId`. `null` when there is none.
  Future<String?> lastBusinessId(String uid);

  /// Records (or with `null`, forgets) [uid]'s current business on this
  /// device and in `users/{uid}`, so another device opens the same one.
  Future<void> rememberBusiness(String uid, String? businessId);
}
