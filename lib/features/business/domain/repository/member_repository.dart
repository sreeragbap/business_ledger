import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';

/// Membership of one business. Reads are live queries on the on-device
/// store; every change goes through an RPC (members are never written by
/// clients), so changes need a connection.
abstract class MemberRepository {
  const MemberRepository();

  /// All members, owner first then by role and name.
  Stream<AppResult<List<Member>>> watchMembers(String businessId);

  /// One membership, live; `null` once removed. Drives the current user's
  /// role, so a demotion applies without a restart.
  Stream<AppResult<Member?>> watchMember(String businessId, String uid);

  /// Returns the new member's uid. The person must have signed in once.
  Future<AppResult<String>> addMember(
    String businessId, {
    required String email,
    required Role role,
  });

  /// [Role.owner] transfers ownership (owner only): the caller becomes admin.
  Future<AppResult<void>> updateRole(
    String businessId, {
    required String uid,
    required Role role,
  });

  /// Removes [uid]; the caller's own uid means "leave".
  Future<AppResult<void>> removeMember(String businessId, String uid);
}
