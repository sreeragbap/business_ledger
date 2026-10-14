part of 'sign_in_cubit.dart';

class SignInState extends Equatable {
  const SignInState({
    this.status = const Status.initial(),
    this.method,
    this.user,
  });

  final Status status;

  /// The provider being tried, so only its button shows a spinner.
  final SocialSignInMethod? method;

  /// Populated only on success.
  final AppUser? user;

  bool isLoading(SocialSignInMethod candidate) =>
      status.isLoading && method == candidate;

  @override
  List<Object?> get props => [status, method, user];
}
