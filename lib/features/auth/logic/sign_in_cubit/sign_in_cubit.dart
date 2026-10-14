import 'package:bloc/bloc.dart';
import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/features/auth/domain/const/social_sign_in_method.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';
import 'package:business_ledger/features/auth/domain/repository/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'sign_in_state.dart';

/// Drives the sign-in screen. A factory, so reopening the screen starts clean.
@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._repository) : super(const SignInState());

  final AuthRepository _repository;

  Future<void> signIn(SocialSignInMethod method) async {
    // One sheet at a time: a second tap while one is open is ignored.
    if (state.status.isLoading) return;

    emit(SignInState(status: const Status.loading(), method: method));
    final result = await _repository.signIn(method);

    result.when(
      success: (user) => emit(
        SignInState(status: const Status.success(), method: method, user: user),
      ),
      // Dismissing the provider sheet is a choice, not an error: back to the
      // resting state with nothing to show.
      failure: (error) => emit(
        error.isCancelled
            ? const SignInState()
            : SignInState(status: Status.fromException(error), method: method),
      ),
    );
  }
}
