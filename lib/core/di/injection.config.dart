// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:business_ledger/core/database/app_database.dart' as _i281;
import 'package:business_ledger/core/database/local_store.dart' as _i408;
import 'package:business_ledger/core/di/register_module.dart' as _i367;
import 'package:business_ledger/core/firebase/connectivity_service.dart' as _i7;
import 'package:business_ledger/core/firebase/crashlytics_service.dart' as _i27;
import 'package:business_ledger/core/router/app_router.dart' as _i901;
import 'package:business_ledger/core/router/guards/auth_guard.dart' as _i650;
import 'package:business_ledger/core/supabase/remote_rpc.dart' as _i296;
import 'package:business_ledger/core/supabase/remote_tables.dart' as _i396;
import 'package:business_ledger/core/supabase/rpc_client.dart' as _i986;
import 'package:business_ledger/core/sync/cloud_availability.dart' as _i272;
import 'package:business_ledger/core/sync/local_writer.dart' as _i1013;
import 'package:business_ledger/core/sync/outbox.dart' as _i308;
import 'package:business_ledger/core/sync/outbox_executor.dart' as _i133;
import 'package:business_ledger/core/sync/outbox_store.dart' as _i661;
import 'package:business_ledger/core/sync/profile_sync.dart' as _i705;
import 'package:business_ledger/core/sync/sync_directory.dart' as _i755;
import 'package:business_ledger/core/sync/sync_engine.dart' as _i783;
import 'package:business_ledger/core/sync/sync_identity.dart' as _i699;
import 'package:business_ledger/core/sync/sync_puller.dart' as _i514;
import 'package:business_ledger/core/sync/sync_queue.dart' as _i670;
import 'package:business_ledger/core/sync/sync_settings.dart' as _i304;
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
import 'package:business_ledger/features/business/domain/repository/business_repository.dart'
    as _i715;
import 'package:business_ledger/features/business/domain/repository/member_repository.dart'
    as _i309;
import 'package:business_ledger/features/business/domain/services/business_service.dart'
    as _i557;
import 'package:business_ledger/features/business/domain/services/member_service.dart'
    as _i792;
import 'package:business_ledger/features/business/logic/business_list_cubit/business_list_cubit.dart'
    as _i788;
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart'
    as _i625;
import 'package:business_ledger/features/business/logic/business_settings_cubit/business_settings_cubit.dart'
    as _i224;
import 'package:business_ledger/features/business/logic/create_business_cubit/create_business_cubit.dart'
    as _i1069;
import 'package:business_ledger/features/business/logic/members_cubit/members_cubit.dart'
    as _i766;
import 'package:business_ledger/features/categories/domain/repository/category_repository.dart'
    as _i385;
import 'package:business_ledger/features/categories/domain/repository/custom_field_repository.dart'
    as _i838;
import 'package:business_ledger/features/categories/domain/services/category_service.dart'
    as _i734;
import 'package:business_ledger/features/categories/domain/services/custom_field_service.dart'
    as _i877;
import 'package:business_ledger/features/categories/logic/categories_cubit/categories_cubit.dart'
    as _i662;
import 'package:business_ledger/features/categories/logic/custom_fields_cubit/custom_fields_cubit.dart'
    as _i819;
import 'package:business_ledger/features/documents/domain/repository/document_output.dart'
    as _i350;
import 'package:business_ledger/features/documents/domain/repository/document_renderer.dart'
    as _i201;
import 'package:business_ledger/features/documents/domain/repository/document_repository.dart'
    as _i465;
import 'package:business_ledger/features/documents/domain/services/document_service.dart'
    as _i209;
import 'package:business_ledger/features/documents/domain/services/pdf_document_renderer.dart'
    as _i753;
import 'package:business_ledger/features/documents/domain/services/printing_document_output.dart'
    as _i751;
import 'package:business_ledger/features/documents/logic/document_cubit/document_cubit.dart'
    as _i373;
import 'package:business_ledger/features/parties/domain/repository/party_repository.dart'
    as _i667;
import 'package:business_ledger/features/parties/domain/services/party_service.dart'
    as _i958;
import 'package:business_ledger/features/parties/logic/parties_cubit/parties_cubit.dart'
    as _i947;
import 'package:business_ledger/features/projects/domain/repository/project_repository.dart'
    as _i360;
import 'package:business_ledger/features/projects/domain/services/project_service.dart'
    as _i896;
import 'package:business_ledger/features/projects/logic/projects_cubit/projects_cubit.dart'
    as _i227;
import 'package:business_ledger/features/reports/domain/repository/reports_repository.dart'
    as _i799;
import 'package:business_ledger/features/reports/domain/services/reports_service.dart'
    as _i188;
import 'package:business_ledger/features/reports/logic/dashboard_cubit/dashboard_cubit.dart'
    as _i1006;
import 'package:business_ledger/features/reports/logic/reports_cubit/reports_cubit.dart'
    as _i1034;
import 'package:business_ledger/features/settings/logic/theme_cubit/theme_cubit.dart'
    as _i622;
import 'package:business_ledger/features/sync/logic/sync_cubit/sync_cubit.dart'
    as _i1051;
import 'package:business_ledger/features/transactions/domain/repository/transaction_repository.dart'
    as _i411;
import 'package:business_ledger/features/transactions/domain/services/transaction_service.dart'
    as _i130;
import 'package:business_ledger/features/transactions/logic/settlement_form_cubit/settlement_form_cubit.dart'
    as _i579;
import 'package:business_ledger/features/transactions/logic/transaction_detail_cubit/transaction_detail_cubit.dart'
    as _i76;
import 'package:business_ledger/features/transactions/logic/transaction_form_cubit/transaction_form_cubit.dart'
    as _i250;
import 'package:business_ledger/features/transactions/logic/transaction_list_cubit/transaction_list_cubit.dart'
    as _i850;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

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
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabase);
    gh.lazySingleton<_i281.AppDatabase>(() => registerModule.database);
    gh.lazySingleton<_i116.GoogleSignIn>(() => registerModule.googleSignIn);
    gh.lazySingleton<_i152.LocalAuthentication>(
      () => registerModule.localAuthentication,
    );
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i27.CrashlyticsService>(() => _i27.CrashlyticsService());
    gh.lazySingleton<_i755.SyncDirectory>(() => _i755.SyncDirectory());
    gh.lazySingleton<_i753.DocumentFontsLoader>(
      () => _i753.DocumentFontsLoader(),
    );
    gh.lazySingleton<_i661.OutboxStore>(
      () => _i661.FileOutboxStore(gh<_i755.SyncDirectory>()),
    );
    gh.lazySingleton<_i201.DocumentRenderer>(
      () => _i753.PdfDocumentRenderer(gh<_i753.DocumentFontsLoader>()),
    );
    gh.lazySingleton<_i308.Outbox>(
      () => _i308.Outbox(gh<_i661.OutboxStore>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i408.LocalStore>(
      () => _i408.LocalStore(gh<_i281.AppDatabase>()),
    );
    gh.lazySingleton<_i619.AppLockRepository>(
      () => _i107.AppLockService(
        gh<_i152.LocalAuthentication>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i350.DocumentOutput>(
      () => const _i751.PrintingDocumentOutput(),
    );
    gh.lazySingleton<_i7.ConnectivityService>(
      () => _i7.ConnectivityService(gh<_i895.Connectivity>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i396.RemoteTables>(
      () => _i396.SupabaseRemoteTables(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i296.RemoteRpc>(
      () => _i296.SupabaseRemoteRpc(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i304.SyncSettings>(
      () => _i304.SyncSettings(gh<_i460.SharedPreferences>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i622.ThemeCubit>(
      () => _i622.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i699.SyncIdentity>(
      () => _i699.FirebaseSyncIdentity(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i514.SyncPuller>(
      () => _i514.SyncPuller(gh<_i396.RemoteTables>(), gh<_i408.LocalStore>()),
    );
    gh.lazySingleton<_i650.AuthGuard>(
      () => _i650.AuthGuard(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i589.AppLockCubit>(
      () => _i589.AppLockCubit(gh<_i619.AppLockRepository>()),
    );
    gh.lazySingleton<_i705.ProfileSync>(
      () => _i705.ProfileSync(gh<_i408.LocalStore>(), gh<_i396.RemoteTables>()),
    );
    gh.lazySingleton<_i901.AppRouter>(
      () => _i901.AppRouter(gh<_i650.AuthGuard>()),
    );
    gh.lazySingleton<_i272.CloudAvailability>(
      () => _i272.CloudAvailability(
        gh<_i7.ConnectivityService>(),
        gh<_i304.SyncSettings>(),
        gh<_i699.SyncIdentity>(),
      ),
    );
    gh.lazySingleton<_i1042.AuthRepository>(
      () => _i369.AuthService(
        gh<_i59.FirebaseAuth>(),
        gh<_i116.GoogleSignIn>(),
        gh<_i705.ProfileSync>(),
        gh<_i27.CrashlyticsService>(),
      ),
    );
    gh.lazySingleton<_i1013.LocalWriter>(
      () => _i1013.LocalWriter(
        gh<_i408.LocalStore>(),
        gh<_i308.Outbox>(),
        gh<_i699.SyncIdentity>(),
        gh<_i396.RemoteTables>(),
        gh<_i272.CloudAvailability>(),
      ),
    );
    gh.lazySingleton<_i986.RpcClient>(
      () =>
          _i986.RpcClient(gh<_i296.RemoteRpc>(), gh<_i272.CloudAvailability>()),
    );
    gh.lazySingleton<_i837.AuthCubit>(
      () => _i837.AuthCubit(gh<_i1042.AuthRepository>()),
    );
    gh.factory<_i610.SignInCubit>(
      () => _i610.SignInCubit(gh<_i1042.AuthRepository>()),
    );
    gh.lazySingleton<_i670.SyncQueue>(
      () => _i670.SyncQueue(
        gh<_i986.RpcClient>(),
        gh<_i308.Outbox>(),
        gh<_i272.CloudAvailability>(),
        gh<_i699.SyncIdentity>(),
        gh<_i514.SyncPuller>(),
      ),
    );
    gh.lazySingleton<_i360.ProjectRepository>(
      () => _i896.ProjectService(
        gh<_i408.LocalStore>(),
        gh<_i1013.LocalWriter>(),
      ),
    );
    gh.factory<_i227.ProjectsCubit>(
      () => _i227.ProjectsCubit(gh<_i360.ProjectRepository>()),
    );
    gh.lazySingleton<_i133.OutboxExecutor>(
      () => _i133.SupabaseOutboxExecutor(
        gh<_i986.RpcClient>(),
        gh<_i396.RemoteTables>(),
      ),
    );
    gh.lazySingleton<_i667.PartyRepository>(
      () =>
          _i958.PartyService(gh<_i408.LocalStore>(), gh<_i1013.LocalWriter>()),
    );
    gh.lazySingleton<_i838.CustomFieldRepository>(
      () => _i877.CustomFieldService(
        gh<_i408.LocalStore>(),
        gh<_i1013.LocalWriter>(),
      ),
    );
    gh.lazySingleton<_i783.SyncEngine>(
      () => _i783.SyncEngine(
        gh<_i308.Outbox>(),
        gh<_i133.OutboxExecutor>(),
        gh<_i7.ConnectivityService>(),
        gh<_i304.SyncSettings>(),
        gh<_i699.SyncIdentity>(),
        gh<_i514.SyncPuller>(),
        gh<_i408.LocalStore>(),
        gh<_i705.ProfileSync>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i819.CustomFieldsCubit>(
      () => _i819.CustomFieldsCubit(gh<_i838.CustomFieldRepository>()),
    );
    gh.lazySingleton<_i465.DocumentRepository>(
      () => _i209.DocumentService(
        gh<_i986.RpcClient>(),
        gh<_i408.LocalStore>(),
        gh<_i783.SyncEngine>(),
      ),
    );
    gh.lazySingleton<_i309.MemberRepository>(
      () => _i792.MemberService(
        gh<_i408.LocalStore>(),
        gh<_i986.RpcClient>(),
        gh<_i783.SyncEngine>(),
      ),
    );
    gh.factory<_i947.PartiesCubit>(
      () => _i947.PartiesCubit(gh<_i667.PartyRepository>()),
    );
    gh.lazySingleton<_i1051.SyncCubit>(
      () => _i1051.SyncCubit(gh<_i783.SyncEngine>(), gh<_i304.SyncSettings>()),
    );
    gh.lazySingleton<_i715.BusinessRepository>(
      () => _i557.BusinessService(
        gh<_i408.LocalStore>(),
        gh<_i986.RpcClient>(),
        gh<_i1013.LocalWriter>(),
        gh<_i460.SharedPreferences>(),
        gh<_i705.ProfileSync>(),
        gh<_i783.SyncEngine>(),
      ),
    );
    gh.factory<_i373.DocumentCubit>(
      () => _i373.DocumentCubit(
        gh<_i465.DocumentRepository>(),
        gh<_i201.DocumentRenderer>(),
        gh<_i350.DocumentOutput>(),
      ),
    );
    gh.lazySingleton<_i799.ReportsRepository>(
      () =>
          _i188.ReportsService(gh<_i408.LocalStore>(), gh<_i783.SyncEngine>()),
    );
    gh.lazySingleton<_i411.TransactionRepository>(
      () => _i130.TransactionService(
        gh<_i408.LocalStore>(),
        gh<_i1013.LocalWriter>(),
        gh<_i699.SyncIdentity>(),
        gh<_i670.SyncQueue>(),
        gh<_i783.SyncEngine>(),
      ),
    );
    gh.lazySingleton<_i385.CategoryRepository>(
      () => _i734.CategoryService(
        gh<_i408.LocalStore>(),
        gh<_i1013.LocalWriter>(),
        gh<_i986.RpcClient>(),
        gh<_i783.SyncEngine>(),
      ),
    );
    gh.factory<_i1006.DashboardCubit>(
      () => _i1006.DashboardCubit(gh<_i799.ReportsRepository>()),
    );
    gh.factory<_i1034.ReportsCubit>(
      () => _i1034.ReportsCubit(gh<_i799.ReportsRepository>()),
    );
    gh.factory<_i579.SettlementFormCubit>(
      () => _i579.SettlementFormCubit(gh<_i411.TransactionRepository>()),
    );
    gh.factory<_i766.MembersCubit>(
      () => _i766.MembersCubit(gh<_i309.MemberRepository>()),
    );
    gh.factory<_i250.TransactionFormCubit>(
      () => _i250.TransactionFormCubit(
        gh<_i411.TransactionRepository>(),
        gh<_i385.CategoryRepository>(),
        gh<_i838.CustomFieldRepository>(),
        gh<_i667.PartyRepository>(),
        gh<_i360.ProjectRepository>(),
        gh<_i272.CloudAvailability>(),
      ),
    );
    gh.factory<_i662.CategoriesCubit>(
      () => _i662.CategoriesCubit(
        gh<_i385.CategoryRepository>(),
        gh<_i838.CustomFieldRepository>(),
      ),
    );
    gh.factory<_i76.TransactionDetailCubit>(
      () => _i76.TransactionDetailCubit(
        gh<_i411.TransactionRepository>(),
        gh<_i838.CustomFieldRepository>(),
        gh<_i272.CloudAvailability>(),
      ),
    );
    gh.factory<_i788.BusinessListCubit>(
      () => _i788.BusinessListCubit(gh<_i715.BusinessRepository>()),
    );
    gh.factory<_i224.BusinessSettingsCubit>(
      () => _i224.BusinessSettingsCubit(gh<_i715.BusinessRepository>()),
    );
    gh.factory<_i1069.CreateBusinessCubit>(
      () => _i1069.CreateBusinessCubit(gh<_i715.BusinessRepository>()),
    );
    gh.lazySingleton<_i625.BusinessScopeCubit>(
      () => _i625.BusinessScopeCubit(
        gh<_i715.BusinessRepository>(),
        gh<_i309.MemberRepository>(),
        gh<_i1042.AuthRepository>(),
      ),
    );
    gh.factory<_i850.TransactionListCubit>(
      () => _i850.TransactionListCubit(
        gh<_i411.TransactionRepository>(),
        gh<_i385.CategoryRepository>(),
        gh<_i667.PartyRepository>(),
        gh<_i360.ProjectRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i367.RegisterModule {}
