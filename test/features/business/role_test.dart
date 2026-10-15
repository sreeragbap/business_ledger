import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rank orders owner > admin > editor > viewer', () {
    expect(
      Role.values.map((role) => role.rank),
      [3, 2, 1, 0],
    );
    expect(Role.admin.atLeast(Role.editor), isTrue);
    expect(Role.editor.atLeast(Role.admin), isFalse);
  });

  test('keys round-trip; unknown keys get the least privilege', () {
    for (final role in Role.values) {
      expect(Role.fromKey(role.key), role);
    }
    expect(Role.fromKey('root'), Role.viewer);
    expect(Role.fromKey(null), Role.viewer);
  });

  test('capabilities match ARCHITECTURE §8', () {
    // (canEditConfig, canDoFinancial, canManageMembers, isOwner)
    final expected = {
      Role.owner: (true, true, true, true),
      Role.admin: (true, true, true, false),
      Role.editor: (true, false, false, false),
      Role.viewer: (false, false, false, false),
    };
    for (final entry in expected.entries) {
      final role = entry.key;
      expect(
        (
          role.canEditConfig,
          role.canDoFinancial,
          role.canManageMembers,
          role.isOwner,
        ),
        entry.value,
        reason: role.key,
      );
      expect(role.canEditBusiness, role.canManageMembers, reason: role.key);
      expect(role.canArchiveBusiness, role.isOwner, reason: role.key);
    }
  });

  test('canManage mirrors the members function', () {
    expect(Role.owner.canManage(Role.admin), isTrue);
    expect(Role.admin.canManage(Role.admin), isFalse);
    expect(Role.admin.canManage(Role.editor), isTrue);
    expect(Role.admin.canManage(Role.viewer), isTrue);
    expect(Role.editor.canManage(Role.viewer), isTrue);
    // Nobody manages the owner: ownership moves only by a transfer.
    expect(Role.owner.canManage(Role.owner), isFalse);
  });

  test('assignable roles: owner hands out admin, admins do not', () {
    expect(Role.owner.assignableRoles, [Role.admin, Role.editor, Role.viewer]);
    expect(Role.admin.assignableRoles, [Role.editor, Role.viewer]);
    expect(Role.viewer.assignableRoles, isEmpty);
  });
}
