import 'package:business_ledger/app/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One-time Supabase client setup, run by `bootstrap()` after Firebase.
///
/// Sign-in stays with Firebase Auth: Supabase *third-party auth* verifies the
/// Firebase ID token sent as the bearer token on every request, and the
/// database reads the caller from it (`app.uid()`). Supabase Auth itself is
/// never used (with `accessToken` set, `client.auth` is unavailable).
abstract final class SupabaseSetup {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      // `getIdToken()` refreshes an expired token by itself; `null` (signed
      // out) sends only the publishable key, which RLS treats as nobody.
      accessToken: () async => FirebaseAuth.instance.currentUser?.getIdToken(),
    );
  }
}
