import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/features/auth/domain/const/social_sign_in_method.dart';
import 'package:business_ledger/features/auth/domain/models/app_user.dart';

/// Contract for the signed-in session. Blocs depend on this, never on
/// `AuthService`, so tests inject a stub.
abstract class AuthRepository {
  const AuthRepository();

  /// The current user, then every change. `null` when signed out.
  Stream<AppUser?> get userChanges;

  AppUser? get currentUser;

  /// Runs the provider sheet, signs in to Firebase and upserts the user's
  /// `profiles` row (Supabase). A dismissed sheet comes back as a [Failure]
  /// whose error `isCancelled`, which the UI treats as "no action".
  Future<AppResult<AppUser>> signIn(SocialSignInMethod method);

  Future<AppResult<void>> signOut();
}
