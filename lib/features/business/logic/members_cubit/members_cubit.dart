import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/domain/repository/member_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'members_state.dart';

/// The members screen: a live list, and the membership RPCs. Every change
/// needs a connection (the RPC client refuses offline with a clear
/// message), and the server's message is shown as is on failure.
@injectable
class MembersCubit extends Cubit<MembersState> {
  MembersCubit(this._repository) : super(const MembersState());

  final MemberRepository _repository;
  StreamSubscription<AppResult<List<Member>>>? _subscription;
  String? _businessId;

  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> watch(String businessId) async {
    _businessId = businessId;
    await _subscription?.cancel();
    emit(state.copyWith(loadStatus: const Status.loading()));
    _subscription = _repository.watchMembers(businessId).listen((result) {
      emit(
        result.when(
          success: (members) => state.copyWith(
            members: members,
            loadStatus: const Status.success(),
          ),
          failure: (error) =>
              state.copyWith(loadStatus: Status.fromException(error)),
        ),
      );
    });
  }

  Future<void> add({required String email, required Role role}) async {
    final trimmed = email.trim();
    if (!emailPattern.hasMatch(trimmed)) {
      emit(
        state.copyWith(
          action: MemberAction.add,
          actionStatus: const Status.failure(
            'Enter a valid email address.',
            errors: {
              'email': ['Enter a valid email address.'],
            },
          ),
        ),
      );
      return;
    }
    await _run(
      MemberAction.add,
      null,
      (id) => _repository.addMember(id, email: trimmed, role: role),
      'Member added.',
    );
  }

  Future<void> changeRole(Member member, Role role) => _run(
    MemberAction.changeRole,
    member.uid,
    (id) => _repository.updateRole(id, uid: member.uid, role: role),
    '${member.name} is now ${_article(role)} ${role.label.toLowerCase()}.',
  );

  Future<void> transferOwnership(Member member) => _run(
    MemberAction.transfer,
    member.uid,
    (id) => _repository.updateRole(id, uid: member.uid, role: Role.owner),
    '${member.name} now owns this business. You are an admin.',
  );

  Future<void> remove(Member member) => _run(
    MemberAction.remove,
    member.uid,
    (id) => _repository.removeMember(id, member.uid),
    '${member.name} was removed.',
  );

  /// The caller leaving. On success the screen drops the business scope.
  Future<void> leave(String uid) => _run(
    MemberAction.leave,
    uid,
    (id) => _repository.removeMember(id, uid),
    'You left the business.',
  );

  Future<void> _run<T>(
    MemberAction action,
    String? targetUid,
    Future<AppResult<T>> Function(String businessId) call,
    String successMessage,
  ) async {
    final businessId = _businessId;
    if (businessId == null || state.actionStatus.isLoading) return;
    emit(
      state.copyWith(
        action: action,
        targetUid: targetUid,
        actionStatus: const Status.loading(),
      ),
    );
    final result = await call(businessId);
    emit(
      state.copyWith(
        actionStatus: result.when(
          success: (_) => Status.success(message: successMessage),
          failure: Status.fromException,
        ),
      ),
    );
  }

  static String _article(Role role) => role == Role.admin ? 'an' : 'a';

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
