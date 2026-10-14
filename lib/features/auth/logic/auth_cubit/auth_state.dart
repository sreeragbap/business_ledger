part of 'auth_cubit.dart';

enum AuthStatus {
  /// Firebase has not reported yet (cold start).
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.signOutStatus = const Status.initial(),
  });

  factory AuthState.from(AppUser? user) => AuthState(
    status: user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated,
    user: user,
  );

  final AuthStatus status;

  /// Present exactly when [status] is authenticated.
  final AppUser? user;
  final Status signOutStatus;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({Status? signOutStatus}) => AuthState(
    status: status,
    user: user,
    signOutStatus: signOutStatus ?? this.signOutStatus,
  );

  @override
  List<Object?> get props => [status, user, signOutStatus];
}
