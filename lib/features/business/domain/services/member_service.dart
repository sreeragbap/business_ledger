import 'dart:async';

import 'package:business_ledger/core/database/app_database.dart';
import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/local_streams.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/domain/json_read.dart';
import 'package:business_ledger/core/supabase/rpc_client.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/domain/repository/member_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

/// [MemberRepository]: members are read from the on-device store; every
/// change is an RPC (online only), after which a pull brings the result.
@LazySingleton(as: MemberRepository)
class MemberService implements MemberRepository {
  MemberService(this._store, this._rpc, this._engine);

  final LocalStore _store;
  final RpcClient _rpc;
  final SyncEngine _engine;

  AppDatabase get _db => _store.db;

  @override
  Stream<AppResult<List<Member>>> watchMembers(String businessId) =>
      LocalStreams.watch(
        (_db.select(_db.members)..where(
              (m) => m.businessId.equals(businessId) & m.deletedAt.isNull(),
            ))
            .watch(),
        (rows) => sortMembers([
          for (final row in rows) Member.fromRow(rowOf(row)),
        ]),
      );

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
      LocalStreams.single(
        (_db.select(_db.members)..where(
              (m) =>
                  m.businessId.equals(businessId) &
                  m.userId.equals(uid) &
                  m.deletedAt.isNull(),
            ))
            .watchSingleOrNull(),
        _store.watchPulled(),
        (row) => Member.fromRow(rowOf(row)),
      );

  @override
  Future<AppResult<String>> addMember(
    String businessId, {
    required String email,
    required Role role,
  }) async {
    final result = await _rpc.call('addMember', {
      'businessId': businessId,
      'email': email.trim().toLowerCase(),
      'role': role.key,
    });
    await _pulled(result);
    return result.map((data) => data.readString('uid'));
  }

  @override
  Future<AppResult<void>> updateRole(
    String businessId, {
    required String uid,
    required Role role,
  }) async {
    final result = await _rpc.call('updateMemberRole', {
      'businessId': businessId,
      'uid': uid,
      'role': role.key,
    });
    await _pulled(result);
    return result.map((_) {});
  }

  @override
  Future<AppResult<void>> removeMember(String businessId, String uid) async {
    final result = await _rpc.call('removeMember', {
      'businessId': businessId,
      'uid': uid,
    });
    await _pulled(result);
    return result.map((_) {});
  }

  /// After a change the server applied, waits (briefly) for the pull that
  /// brings it into the local store.
  Future<void> _pulled(AppResult<Object?> result) async {
    if (result.isFailure) return;
    try {
      await _engine.refresh().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // It arrives with the pull's completion.
    }
  }
}
