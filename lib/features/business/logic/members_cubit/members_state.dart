part of 'members_cubit.dart';

enum MemberAction { add, changeRole, transfer, remove, leave }

class MembersState extends Equatable {
  const MembersState({
    this.members,
    this.loadStatus = const Status.initial(),
    this.action,
    this.targetUid,
    this.actionStatus = const Status.initial(),
  });

  /// `null` until the first snapshot.
  final List<Member>? members;
  final Status loadStatus;

  /// The last membership operation, and whom it was about, so the screen
  /// can show progress on the right row and react to the right success.
  final MemberAction? action;
  final String? targetUid;
  final Status actionStatus;

  bool isBusy(String uid) => actionStatus.isLoading && targetUid == uid;

  MembersState copyWith({
    List<Member>? members,
    Status? loadStatus,
    MemberAction? action,
    String? targetUid,
    Status? actionStatus,
  }) => MembersState(
    members: members ?? this.members,
    loadStatus: loadStatus ?? this.loadStatus,
    action: action ?? this.action,
    targetUid: action != null ? targetUid : this.targetUid,
    actionStatus: actionStatus ?? this.actionStatus,
  );

  @override
  List<Object?> get props => [
    members,
    loadStatus,
    action,
    targetUid,
    actionStatus,
  ];
}
