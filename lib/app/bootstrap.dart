import 'dart:async';
import 'dart:developer' as developer;

import 'package:business_ledger/app/app.dart';
import 'package:business_ledger/app/app_config.dart';
import 'package:business_ledger/app/flavor.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/firebase/crashlytics_service.dart';
import 'package:business_ledger/core/firebase/firebase_setup.dart';
import 'package:business_ledger/core/supabase/supabase_setup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared startup path for every flavor.
///
/// Order matters:
///   1. Flavor, because [AppConfig] reads it and everything below reads that.
///   2. Firebase, so Crashlytics can capture failures from step 3 onward.
///   3. Error handlers, before any app code can throw.
///   4. SDK setup: the Auth emulator (if asked for) and the Supabase client
///      (its bearer token is the Firebase ID token), before anything uses
///      them.
///   5. DI, so services exist. The sync engine (started by `App`) reads
///      the Cloud sync switch itself: with it off, nothing is sent.
///   6. `runApp`.
Future<void> bootstrap(Flavor flavor) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Portrait only; also set natively (Info.plist, AndroidManifest.xml)
      // so the launch screen does not rotate either.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      AppConfig.configure(flavor);

      FirebaseOptions options;
      try {
        options = AppConfig.firebaseOptions;
        // The placeholder options throw an Error by design (it is a setup
        // mistake, not a runtime condition); this is the one place it is
        // turned into something visible.
        // ignore: avoid_catching_errors
      } on UnimplementedError catch (error) {
        if (!AppConfig.useEmulator) {
          // The placeholder options file is still in place. Say so on screen
          // instead of crashing to a blank one.
          runApp(_ConfigurationErrorApp(message: '${error.message}'));
          return;
        }
        // Emulator run before `flutterfire configure`: a demo project is
        // enough, since nothing leaves the machine.
        AppConfig.usingDemoProject = true;
        options = AppConfig.demoOptions;
      }

      await Firebase.initializeApp(options: options);

      if (!AppConfig.usingDemoProject) {
        final crashlytics = CrashlyticsService();
        await crashlytics.initialise();
        crashlytics.installErrorHandlers();
      }

      await FirebaseSetup.configure();
      await SupabaseSetup.initialize();
      await configureDependencies();

      runApp(const App());
    },
    (error, stack) {
      developer.log(
        'Uncaught zone error',
        name: 'bootstrap',
        error: error,
        stackTrace: stack,
      );
      if (Firebase.apps.isNotEmpty) {
        unawaited(CrashlyticsService().recordError(error, stack, fatal: true));
      }
    },
  );
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SelectableText(
                'Firebase is not configured.\n\n$message',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
