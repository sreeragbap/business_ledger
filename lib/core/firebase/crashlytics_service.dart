import 'dart:async';

import 'package:business_ledger/app/app_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Crash and non-fatal error reporting.
///
/// Collection is disabled in debug so local experiments do not pollute the
/// dashboards, and every report is tagged with the flavor.
@lazySingleton
class CrashlyticsService {
  CrashlyticsService() : _crashlytics = FirebaseCrashlytics.instance;

  /// Test seam, kept off the injectable constructor.
  @visibleForTesting
  CrashlyticsService.withCrashlytics(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  Future<void> initialise() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    await _crashlytics.setCustomKey('flavor', AppConfig.flavor.name);
  }

  /// Routes framework and platform errors into Crashlytics. Called from
  /// `bootstrap()` before `runApp`.
  void installErrorHandlers() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      unawaited(_crashlytics.recordFlutterFatalError(details));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(_crashlytics.recordError(error, stack, fatal: true));
      return true;
    };
  }

  /// The emulator demo project has no Crashlytics app behind it.
  bool get _enabled => !AppConfig.usingDemoProject;

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_enabled) {
      debugPrint('[crashlytics:off] $reason: $error');
      return;
    }
    await _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);
  }

  Future<void> log(String message) async {
    if (_enabled) await _crashlytics.log(message);
  }

  Future<void> setUserIdentifier(String id) async {
    if (_enabled) await _crashlytics.setUserIdentifier(id);
  }

  Future<void> clearUserIdentifier() async {
    if (_enabled) await _crashlytics.setUserIdentifier('');
  }
}
