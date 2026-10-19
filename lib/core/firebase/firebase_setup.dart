import 'dart:developer' as developer;

import 'package:business_ledger/app/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-time Firebase configuration, run by `bootstrap()` after
/// `Firebase.initializeApp`. Firebase only signs people in (and reports
/// crashes); data lives in Supabase (`core/supabase`).
abstract final class FirebaseSetup {
  static Future<void> configure() async {
    if (AppConfig.useEmulator) await _useEmulators();
  }

  static Future<void> _useEmulators() async {
    final host = AppConfig.emulatorHost;
    developer.log(
      'Using the Firebase Auth emulator on $host',
      name: 'firebase',
    );
    await FirebaseAuth.instance.useAuthEmulator(
      host,
      AppConfig.authEmulatorPort,
      automaticHostMapping: false,
    );
  }
}
