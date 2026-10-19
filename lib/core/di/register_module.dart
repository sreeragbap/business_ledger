import 'package:business_ledger/core/database/app_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Third-party instances that cannot carry an injectable annotation.
///
/// Registered here rather than built inside each service (the reference's
/// `withX` test-constructor pattern) so services take them as plain
/// constructor parameters and tests pass fakes the same way.
@module
abstract class RegisterModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  /// Initialised by `bootstrap()` (`SupabaseSetup`) before DI is used.
  @lazySingleton
  SupabaseClient get supabase => Supabase.instance.client;

  /// The on-device store. Opened lazily on first query.
  @lazySingleton
  AppDatabase get database => AppDatabase.open();

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;

  @lazySingleton
  LocalAuthentication get localAuthentication => LocalAuthentication();

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  /// Resolved during `configureDependencies()` so reads are synchronous.
  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
