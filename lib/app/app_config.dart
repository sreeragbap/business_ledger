import 'package:business_ledger/app/firebase_options_dev.dart' as dev;
import 'package:business_ledger/app/firebase_options_prod.dart' as prod;
import 'package:business_ledger/app/flavor.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Per-flavor runtime configuration.
///
/// [flavor] is set once by `bootstrap()`, before anything reads it. Reading a
/// member earlier throws, which is deliberate: a missing flavor assignment
/// surfaces at once instead of silently running against the wrong project.
abstract final class AppConfig {
  static Flavor? _flavor;

  static Flavor get flavor =>
      _flavor ??
      (throw StateError('AppConfig.flavor read before bootstrap() set it.'));

  /// Called by `bootstrap()`. A second call with a different flavor is a bug.
  static void configure(Flavor flavor) {
    assert(
      _flavor == null || _flavor == flavor,
      'AppConfig is already configured for $_flavor.',
    );
    _flavor = flavor;
  }

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;

  static String get appName => flavor.title;

  /// Show the debug banner only outside production.
  static bool get showDebugBanner => isDev && kDebugMode;

  static FirebaseOptions get firebaseOptions => switch (flavor) {
    Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
    Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
  };

  // --- Supabase (data) -----------------------------------------------------
  // Project `unvpyjnotaukdxgmpytr` (Mumbai). The publishable key is meant to
  // ship in the app: on its own it reads and writes nothing (row level
  // security requires a verified Firebase ID token, `supabase/README.md`).
  // Prod uses the same project as dev for now.

  static String get supabaseUrl => switch (flavor) {
    Flavor.dev || Flavor.prod => 'https://unvpyjnotaukdxgmpytr.supabase.co',
  };

  static String get supabasePublishableKey => switch (flavor) {
    Flavor.dev ||
    Flavor.prod => 'sb_publishable_pCp1Rex66kanRMkbingnNg_rbdkSzn_',
  };

  // --- Local emulators -----------------------------------------------------
  // `flutter run -t lib/main_dev.dart --dart-define=USE_EMULATOR=true`
  // Only the Firebase **Auth** emulator is used (port from `firebase.json`),
  // for the "Continue with test account" sign-in. Data lives in Supabase,
  // which does not accept the emulator's unsigned tokens: emulator mode
  // needs a local Supabase (`npx supabase start`) configured to trust them,
  // so against the hosted project it shows no businesses and every RPC
  // answers "Sign in to continue". A physical device needs the host
  // machine's LAN address: add `--dart-define=EMULATOR_HOST=192.168.x.y`.

  static const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

  static const String _emulatorHostOverride = String.fromEnvironment(
    'EMULATOR_HOST',
  );

  /// `10.0.2.2` is the Android emulator's alias for the host's loopback.
  static String get emulatorHost {
    if (_emulatorHostOverride.isNotEmpty) return _emulatorHostOverride;
    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }

  static const int authEmulatorPort = 9099;

  /// Project id for emulator runs before `flutterfire configure`. The
  /// `demo-` prefix tells the emulators never to reach a real project.
  static const String demoProjectId = 'demo-business-ledger';

  /// Set by `bootstrap()` when running on [demoOptions]: no real Firebase app
  /// exists, so Crashlytics and Google/Apple sign-in are unavailable.
  static bool usingDemoProject = false;

  static FirebaseOptions get demoOptions => FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: defaultTargetPlatform == TargetPlatform.android
        ? '1:000000000000:android:0000000000000000'
        : '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: demoProjectId,
  );
}
