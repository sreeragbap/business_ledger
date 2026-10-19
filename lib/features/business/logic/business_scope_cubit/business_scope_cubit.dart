import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/domain/repository/auth_repository.dart';
import 'package:business_ledger/features/business/domain/const/role.dart';
import 'package:business_ledger/features/business/domain/models/business.dart';
import 'package:business_ledger/features/business/domain/models/member.dart';
import 'package:business_ledger/features/business/domain/repository/business_repository.dart';
import 'package:business_ledger/features/business/domain/repository/member_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'business_scope_state.dart';

/// The business the app is working in, and the signed-in user's role in it.
///
/// App-wide singleton, like `AuthCubit`: every screen reads the current
/// business id and role from here. It streams both the business document
/// and the user's own membership document, so a rename, a settings change
/// or a demotion applies live, and losing access (removed, business gone)
/// drops the selection with [BusinessScopeState.lostMessage] set.
///
/// The choice is remembered per user on the device and in
/// `profiles.last_business_id`, so a restart (or another device) reopens it.
@lazySingleton
class BusinessScopeCubit extends Cubit<BusinessScopeState> {
  BusinessScopeCubit(this._businesses, this._members, this._auth)
    : super(const BusinessScopeState()) {
    _uid = _auth.currentUser?.uid;
    _authSubscription = _auth.userChanges.listen(_onUser);
  }

  final BusinessRepository _businesses;
  final MemberRepository _members;
  final AuthRepository _auth;

  late final StreamSubscription<AppUser?> _authSubscription;
  StreamSubscription<AppResult<Business?>>? _businessSubscription;
  StreamSubscription<AppResult<Member?>>? _memberSubscription;
  String? _uid;

  /// Re-selects the user's last business. Returns its id, or `null` when
  /// there is none and the picker should show. Safe to call repeatedly.
  Future<String?> restore() async {
    final uid = await _syncUser(_auth.currentUser?.uid);
    if (uid == null) return null;
    if (state.businessId != null && state.status != ScopeStatus.none) {
      return state.businessId;
    }
    final id = await _businesses.lastBusinessId(uid);
    if (isClosed || uid != _uid) return null;
    if (id == null) {
      emit(const BusinessScopeState(status: ScopeStatus.none));
      return null;
    }
    await select(id);
    return id;
  }

  /// Makes [businessId] current and remembers the choice.
  Future<void> select(String businessId) async {
    final uid = await _syncUser(_auth.currentUser?.uid);
    if (uid == null) return;
    if (businessId == state.businessId && _businessSubscription != null) {
      return;
    }
    await _cancelStreams();
    emit(
      BusinessScopeState(status: ScopeStatus.loading, businessId: businessId),
    );
    _businessSubscription = _businesses
        .watchBusiness(businessId)
        .listen(_onBusiness);
    _memberSubscription = _members
        .watchMember(businessId, uid)
        .listen(_onMember);
    // Not awaited: the remote half waits for the server when online, and
    // nothing on screen depends on it.
    unawaited(_businesses.rememberBusiness(uid, businessId));
  }

  /// Drops the selection (after leaving a business, say) and forgets it.
  Future<void> clear({String? message}) async {
    await _cancelStreams();
    final uid = _uid;
    if (uid != null) unawaited(_businesses.rememberBusiness(uid, null));
    if (isClosed) return;
    emit(BusinessScopeState(status: ScopeStatus.none, lostMessage: message));
  }

  void _onBusiness(AppResult<Business?> result) {
    switch (result) {
      case Success(data: null):
        unawaited(clear(message: 'That business no longer exists.'));
      case Success(:final data?):
        emit(
          state.copyWith(
            business: data,
            status: state.member == null
                ? ScopeStatus.loading
                : ScopeStatus.ready,
            loadStatus: const Status.success(),
          ),
        );
      case Failure(:final error):
        _onStreamError(error);
    }
  }

  void _onMember(AppResult<Member?> result) {
    switch (result) {
      case Success(data: null):
        final name = state.business?.name;
        unawaited(
          clear(
            message: name == null
                ? 'You no longer have access to that business.'
                : 'You no longer have access to $name.',
          ),
        );
      case Success(:final data?):
        emit(
          state.copyWith(
            member: data,
            status: state.business == null
                ? ScopeStatus.loading
                : ScopeStatus.ready,
            loadStatus: const Status.success(),
          ),
        );
      case Failure(:final error):
        _onStreamError(error);
    }
  }

  void _onStreamError(AppException error) {
    // Removed from the business: the rules now refuse every read.
    if (error.kind == AppErrorKind.permissionDenied) {
      unawaited(
        clear(message: 'You no longer have access to that business.'),
      );
      return;
    }
    // Anything else (a flaky network) keeps what is on screen.
    emit(state.copyWith(loadStatus: Status.fromException(error)));
  }

  Future<void> _onUser(AppUser? user) => _syncUser(user?.uid);

  /// Adopts [uid] as the signed-in user, dropping everything held for a
  /// previous one. Called from the auth stream and, because that stream can
  /// lag a fresh sign-in by a moment, before every restore and select.
  Future<String?> _syncUser(String? uid) async {
    if (uid == _uid) return uid;
    _uid = uid;
    await _cancelStreams();
    if (!isClosed) emit(const BusinessScopeState());
    return uid;
  }

  Future<void> _cancelStreams() async {
    await _businessSubscription?.cancel();
    await _memberSubscription?.cancel();
    _businessSubscription = null;
    _memberSubscription = null;
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _cancelStreams();
    return super.close();
  }
}
