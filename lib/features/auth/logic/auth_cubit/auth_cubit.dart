import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/domain/repository/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'auth_state.dart';

/// The app-wide session: who is signed in, and signing out.
///
/// A singleton, unlike screen blocs: the router, the app lock and every
/// screen agree on one session.
@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(AuthState.from(_repository.currentUser)) {
    _subscription = _repository.userChanges.listen(
      (user) => emit(
        AuthState.from(user).copyWith(signOutStatus: state.signOutStatus),
      ),
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  Future<void> signOut() async {
    if (state.signOutStatus.isLoading) return;
    emit(state.copyWith(signOutStatus: const Status.loading()));
    final result = await _repository.signOut();
    emit(
      state.copyWith(
        signOutStatus: result.when(
          success: (_) => const Status.success(),
          failure: Status.fromException,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
