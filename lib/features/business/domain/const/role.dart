/// A member's role in one business. Keys are shared with the security rules
/// and `functions/src/lib/roles.ts`; [rank] mirrors both.
///
/// The UI reads the capability getters rather than comparing roles, so the
/// question "may this person do X" has one answer in one place. They decide
/// what is *shown*; rules and functions decide what is *allowed*.
enum Role {
  owner('owner', 'Owner', 3, 'Everything, including ownership and archiving.'),
  admin('admin', 'Admin', 2, 'Confirms money, manages members and settings.'),
  editor('editor', 'Editor', 1, 'Records drafts and edits configuration.'),
  viewer('viewer', 'Viewer', 0, 'Can see everything, change nothing.');

  const Role(this.key, this.label, this.rank, this.description);

  final String key;
  final String label;
  final int rank;
  final String description;

  /// Unknown keys fall to the least privilege.
  static Role fromKey(Object? key) =>
      values.firstWhere((role) => role.key == key, orElse: () => viewer);

  bool atLeast(Role other) => rank >= other.rank;

  bool get isOwner => this == owner;

  /// Categories, fields, parties, projects and drafts.
  bool get canEditConfig => atLeast(editor);

  /// Confirm, edit confirmed, cancel, settle.
  bool get canDoFinancial => atLeast(admin);

  bool get canManageMembers => atLeast(admin);

  /// Name, description, time zone and settings.
  bool get canEditBusiness => atLeast(admin);

  bool get canArchiveBusiness => isOwner;

  bool get canTransferOwnership => isOwner;

  /// Mirrors `canManage` in `functions/src/handlers/members.ts`: admins
  /// manage editors and viewers; only the owner manages admins. Nobody
  /// manages the owner (ownership moves only by a transfer).
  bool canManage(Role target) =>
      target != owner && (isOwner || rank > target.rank);

  /// Roles this role may hand out when adding or changing a member.
  List<Role> get assignableRoles => [
    for (final role in const [admin, editor, viewer])
      if (canManage(role)) role,
  ];
}
