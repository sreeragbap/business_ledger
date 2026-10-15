import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/firebase/callable_client.dart';
import 'package:business_ledger/core/firebase/firestore_read.dart';
import 'package:business_ledger/core/firebase/firestore_refs.dart';
import 'package:business_ledger/core/firebase/firestore_streams.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/domain/repository/member_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: MemberRepository)
class MemberService implements MemberRepository {
  MemberService(this._refs, this._callable);

  final FirestoreRefs _refs;
  final CallableClient _callable;

  @override
  Stream<AppResult<List<Member>>> watchMembers(String businessId) =>
      FirestoreStreams.list(
        _refs.members(businessId),
        Member.fromFirestore,
      ).map((result) => result.map(sortMembers));

  /// Owner first, then by role, then by name.
  static List<Member> sortMembers(List<Member> members) =>
      List<Member>.unmodifiable(
        List<Member>.of(members)..sort((a, b) {
          final byRole = b.role.rank.compareTo(a.role.rank);
          if (byRole != 0) return byRole;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }),
      );

  @override
  Stream<AppResult<Member?>> watchMember(String businessId, String uid) =>
      FirestoreStreams.doc(_refs.member(businessId, uid), Member.fromFirestore);

  @override
  Future<AppResult<String>> addMember(
    String businessId, {
    required String email,
    required Role role,
  }) async {
    final result = await _callable.call('addMember', {
      'businessId': businessId,
      'email': email.trim().toLowerCase(),
      'role': role.key,
    });
    return result.map((data) => data.readString('uid'));
  }

  @override
  Future<AppResult<void>> updateRole(
    String businessId, {
    required String uid,
    required Role role,
  }) async {
    final result = await _callable.call('updateMemberRole', {
      'businessId': businessId,
      'uid': uid,
      'role': role.key,
    });
    return result.map((_) {});
  }

  @override
  Future<AppResult<void>> removeMember(String businessId, String uid) async {
    final result = await _callable.call('removeMember', {
      'businessId': businessId,
      'uid': uid,
    });
    return result.map((_) {});
  }
}
