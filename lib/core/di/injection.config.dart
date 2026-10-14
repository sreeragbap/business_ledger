// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:business_ledger/core/di/register_module.dart' as _i367;
import 'package:business_ledger/core/firebase/callable_client.dart' as _i252;
import 'package:business_ledger/core/firebase/connectivity_service.dart' as _i7;
import 'package:business_ledger/core/firebase/crashlytics_service.dart' as _i27;
import 'package:business_ledger/core/firebase/firestore_refs.dart' as _i1058;
import 'package:business_ledger/core/logic/connectivity_cubit.dart' as _i672;
import 'package:business_ledger/core/router/app_router.dart' as _i901;
import 'package:business_ledger/core/router/guards/auth_guard.dart' as _i650;
import 'package:business_ledger/features/app_lock/domain/repository/app_lock_repository.dart'
    as _i619;
import 'package:business_ledger/features/app_lock/domain/services/app_lock_service.dart'
    as _i107;
import 'package:business_ledger/features/app_lock/logic/app_lock_cubit/app_lock_cubit.dart'
    as _i589;
import 'package:business_ledger/features/auth/domain/repository/auth_repository.dart'
    as _i1042;
import 'package:business_ledger/features/auth/domain/services/auth_service.dart'
    as _i369;
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart'
    as _i837;
import 'package:business_ledger/features/auth/logic/sign_in_cubit/sign_in_cubit.dart'
    as _i610;
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:cloud_functions/cloud_functions.dart' as _i809;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => registerModule.firestore);
    gh.lazySingleton<_i809.FirebaseFunctions>(() => registerModule.functions);
    gh.lazySingleton<_i457.FirebaseStorage>(() => registerModule.storage);
    gh.lazySingleton<_i116.GoogleSignIn>(() => registerModule.googleSignIn);
    gh.lazySingleton<_i152.LocalAuthentication>(
      () => registerModule.localAuthentication,
    );
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i27.CrashlyticsService>(() => _i27.CrashlyticsService());
    gh.lazySingleton<_i619.AppLockRepository>(
      () => _i107.AppLockService(
        gh<_i152.LocalAuthentication>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i1058.FirestoreRefs>(
      () => _i1058.FirestoreRefs(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i7.ConnectivityService>(
      () => _i7.ConnectivityService(gh<_i895.Connectivity>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i1042.AuthRepository>(
      () => _i369.AuthService(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
        gh<_i1058.FirestoreRefs>(),
        gh<_i27.CrashlyticsService>(),
      ),
    );
    gh.lazySingleton<_i252.CallableClient>(
      () => _i252.CallableClient(
        gh<_i809.FirebaseFunctions>(),
        gh<_i7.ConnectivityService>(),
      ),
    );
    gh.lazySingleton<_i650.AuthGuard>(
      () => _i650.AuthGuard(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i589.AppLockCubit>(
      () => _i589.AppLockCubit(gh<_i619.AppLockRepository>()),
    );
    gh.lazySingleton<_i837.AuthCubit>(
      () => _i837.AuthCubit(gh<_i1042.AuthRepository>()),
    );
    gh.factory<_i610.SignInCubit>(
      () => _i610.SignInCubit(gh<_i1042.AuthRepository>()),
    );
    gh.lazySingleton<_i672.ConnectivityCubit>(
      () => _i672.ConnectivityCubit(gh<_i7.ConnectivityService>()),
    );
    gh.lazySingleton<_i901.AppRouter>(
      () => _i901.AppRouter(gh<_i650.AuthGuard>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i367.RegisterModule {}
