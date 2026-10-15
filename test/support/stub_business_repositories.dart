import 'dart:async';

import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/create_business_request.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/domain/repository/business_repository.dart';
import 'package:business_ledger/features/business/domain/repository/member_repository.dart';
import 'package:business_ledger/features/categories/domain/models/category.dart';
import 'package:business_ledger/features/categories/domain/models/custom_field.dart';
import 'package:business_ledger/features/categories/domain/repository/category_repository.dart';
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart';
import 'package:business_ledger/features/parties/domain/models/party.dart';
import 'package:business_ledger/features/parties/domain/repository/party_repository.dart';

/// Hand-written repositories for cubit tests. Push stream values through the
/// public controllers; set `*Result` fields before acting; read the
/// recorded calls afterwards.

class StubBusinessRepository extends BusinessRepository {
  final StreamController<AppResult<List<Business>>> myBusinesses =
      StreamController.broadcast();
  final Map<String, StreamController<AppResult<Business?>>> businesses = {};

  StreamController<AppResult<Business?>> business(String id) =>
      businesses.putIfAbsent(id, StreamController.broadcast);

  /// Per-uid stored last business, as `users/{uid}.lastBusinessId` would be.
  final Map<String, String?> lastIds = {};
  final List<(String, String?)> rememberCalls = [];

  AppResult<String> createResult = const Success('b-new');
  final List<CreateBusinessRequest> createCalls = [];

  AppResult<void> updateResult = const Success(null);
  AppResult<void> archiveResult = const Success(null);
  final List<String> updateCalls = [];

  @override
  Stream<AppResult<List<Business>>> watchMyBusinesses(String uid) =>
      myBusinesses.stream;

  @override
  Stream<AppResult<Business?>> watchBusiness(String businessId) =>
      business(businessId).stream;

  @override
  Future<AppResult<String>> createBusiness(
    CreateBusinessRequest request,
  ) async {
    createCalls.add(request);
    return createResult;
  }

  @override
  Future<AppResult<void>> updateDetails(
    String businessId, {
    required String name,
    required String description,
    required String timezone,
    required BusinessSettings settings,
  }) async {
    updateCalls.add(businessId);
    return updateResult;
  }

  @override
  Future<AppResult<void>> setArchived(
    String businessId, {
    required bool archived,
  }) async => archiveResult;

  @override
  Future<String?> lastBusinessId(String uid) async => lastIds[uid];

  @override
  Future<void> rememberBusiness(String uid, String? businessId) async {
    rememberCalls.add((uid, businessId));
    lastIds[uid] = businessId;
  }

  Future<void> dispose() async {
    await myBusinesses.close();
    for (final controller in businesses.values) {
      await controller.close();
    }
  }
}

class StubMemberRepository extends MemberRepository {
  final StreamController<AppResult<List<Member>>> members =
      StreamController.broadcast();
  final Map<String, StreamController<AppResult<Member?>>> memberships = {};

  StreamController<AppResult<Member?>> membership(String businessId) =>
      memberships.putIfAbsent(businessId, StreamController.broadcast);

  AppResult<String> addResult = const Success('u-new');
  AppResult<void> updateResult = const Success(null);
  AppResult<void> removeResult = const Success(null);
  final List<String> calls = [];

  @override
  Stream<AppResult<List<Member>>> watchMembers(String businessId) =>
      members.stream;

  @override
  Stream<AppResult<Member?>> watchMember(String businessId, String uid) =>
      membership(businessId).stream;

  @override
  Future<AppResult<String>> addMember(
    String businessId, {
    required String email,
    required Role role,
  }) async {
    calls.add('add:$email:${role.key}');
    return addResult;
  }

  @override
  Future<AppResult<void>> updateRole(
    String businessId, {
    required String uid,
    required Role role,
  }) async {
    calls.add('role:$uid:${role.key}');
    return updateResult;
  }

  @override
  Future<AppResult<void>> removeMember(String businessId, String uid) async {
    calls.add('remove:$uid');
    return removeResult;
  }

  Future<void> dispose() async {
    await members.close();
    for (final controller in memberships.values) {
      await controller.close();
    }
  }
}

class StubCategoryRepository extends CategoryRepository {
  final StreamController<AppResult<List<Category>>> categories =
      StreamController.broadcast();

  AppResult<String> createResult = const Success('c-new');
  AppResult<void> writeResult = const Success(null);
  AppResult<void> deleteResult = const Success(null);

  final List<Category> created = [];
  final List<Category> updated = [];
  final List<Map<String, int>> reorders = [];
  final List<(String, bool, int?)> archiveCalls = [];
  final List<String> deleteCalls = [];

  @override
  Stream<AppResult<List<Category>>> watchCategories(String businessId) =>
      categories.stream;

  @override
  Future<AppResult<Category?>> getCategory(
    String businessId,
    String id,
  ) async => const Success(null);

  @override
  Future<AppResult<String>> create(String businessId, Category category) async {
    created.add(category);
    return createResult;
  }

  @override
  Future<AppResult<void>> update(String businessId, Category category) async {
    updated.add(category);
    return writeResult;
  }

  @override
  Future<AppResult<void>> reorder(
    String businessId,
    Map<String, int> orders,
  ) async {
    reorders.add(orders);
    return writeResult;
  }

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
    int? sortOrder,
  }) async {
    archiveCalls.add((id, archived, sortOrder));
    return writeResult;
  }

  @override
  Future<AppResult<void>> delete(String businessId, String id) async {
    deleteCalls.add(id);
    return deleteResult;
  }

  Future<void> dispose() => categories.close();
}

class StubCustomFieldRepository extends CustomFieldRepository {
  final StreamController<AppResult<List<CustomField>>> fields =
      StreamController.broadcast();

  AppResult<String> createResult = const Success('f-new');
  AppResult<void> writeResult = const Success(null);
  final List<CustomField> created = [];
  final List<Map<String, int>> reorders = [];

  @override
  Stream<AppResult<List<CustomField>>> watchFields(String businessId) =>
      fields.stream;

  @override
  Future<AppResult<String>> create(String businessId, CustomField field) async {
    created.add(field);
    return createResult;
  }

  @override
  Future<AppResult<void>> update(String businessId, CustomField field) async =>
      writeResult;

  @override
  Future<AppResult<void>> reorder(
    String businessId,
    Map<String, int> orders,
  ) async {
    reorders.add(orders);
    return writeResult;
  }

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
    int? sortOrder,
  }) async => writeResult;

  Future<void> dispose() => fields.close();
}

class StubPartyRepository extends PartyRepository {
  final StreamController<AppResult<List<Party>>> parties =
      StreamController.broadcast();

  AppResult<String> createResult = const Success('p-new');
  AppResult<void> writeResult = const Success(null);
  final List<Party> created = [];

  @override
  Stream<AppResult<List<Party>>> watchParties(String businessId) =>
      parties.stream;

  @override
  Future<AppResult<Party?>> getParty(String businessId, String id) async =>
      const Success(null);

  @override
  Future<AppResult<String>> create(String businessId, Party party) async {
    created.add(party);
    return createResult;
  }

  @override
  Future<AppResult<void>> update(String businessId, Party party) async =>
      writeResult;

  @override
  Future<AppResult<void>> setArchived(
    String businessId,
    String id, {
    required bool archived,
  }) async => writeResult;

  Future<void> dispose() => parties.close();
}
