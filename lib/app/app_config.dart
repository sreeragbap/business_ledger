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

  /// Every callable is deployed here (`functions/src/lib/callable.ts`).
  static const String functionsRegion = 'asia-south1';

  // --- Local emulators -----------------------------------------------------
  // `flutter run -t lib/main_dev.dart --dart-define=USE_EMULATOR=true`
  // Ports match `firebase.json`. A physical device needs the host machine's
  // LAN address: add `--dart-define=EMULATOR_HOST=192.168.x.y`.

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
  static const int firestoreEmulatorPort = 8080;
  static const int functionsEmulatorPort = 5001;
  static const int storageEmulatorPort = 9199;

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
    storageBucket: '$demoProjectId.appspot.com',
  );
}
