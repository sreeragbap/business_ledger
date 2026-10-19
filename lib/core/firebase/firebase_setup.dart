import 'dart:developer' as developer;

import 'package:business_ledger/app/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-time SDK configuration, run by `bootstrap()` after
/// `Firebase.initializeApp` and before anything reads an instance.
abstract final class FirebaseSetup {
  static Future<void> configure() async {
    // Settings first: `useFirestoreEmulator` layers its host on top of them,
    // and assigning settings afterwards is easy to get wrong.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (AppConfig.useEmulator) await _useEmulators();
  }

  static Future<void> _useEmulators() async {
    final host = AppConfig.emulatorHost;
    developer.log('Using Firebase emulators on $host', name: 'firebase');

    await FirebaseAuth.instance.useAuthEmulator(
      host,
      AppConfig.authEmulatorPort,
      automaticHostMapping: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      AppConfig.firestoreEmulatorPort,
      // The host is already resolved per platform; do not remap it.
      automaticHostMapping: false,
    );
    FirebaseFunctions.instanceFor(
      region: AppConfig.functionsRegion,
    ).useFunctionsEmulator(
      host,
      AppConfig.functionsEmulatorPort,
      automaticHostMapping: false,
    );
  }
}
