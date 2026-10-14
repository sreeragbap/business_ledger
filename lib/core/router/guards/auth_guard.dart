import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/router/app_router.gr.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

/// Blocks guarded routes when nobody is signed in.
///
/// Runs on every navigation into a guarded branch, so a session that ends
/// mid-run cannot leave the user on an authenticated screen.
@lazySingleton
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // `currentUser` can lag a cold start by a frame; the first
    // `authStateChanges` event is authoritative.
    final user = _auth.currentUser ?? await _auth.authStateChanges().first;
    if (user != null) {
      resolver.next();
      return;
    }
    // Holds the navigation and shows sign-in instead. Sign-in finishes with
    // `replaceAll`, discarding this pending navigation, so back can never
    // land on a protected screen.
    resolver.redirectUntil(const SignInRoute());
  }
}
