import 'dart:async';

import 'package:business_ledger/app/app_config.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/firebase/local_first_writer.dart';
import 'package:business_ledger/core/responsive/app_screen_util.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_status.dart';
import 'package:business_ledger/core/theme/app_theme.dart';
import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:business_ledger/features/app_lock/logic/app_lock_cubit/app_lock_cubit.dart';
import 'package:business_ledger/features/auth/logic/auth_cubit/auth_cubit.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:business_ledger/features/sync/logic/sync_cubit/sync_cubit.dart';
import 'package:business_ledger/features/sync/widgets/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root widget.
///
/// Owns the app-wide concerns that cannot live in a feature: leaving the
/// signed-in area when the session ends, locking after time in the
/// background, the sync engine and its status banner.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _router = getIt<AppRouter>();
  late final AuthCubit _auth = getIt<AuthCubit>();
  late final AppLockCubit _lock = getIt<AppLockCubit>();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // Hidden/shown rather than paused/resumed: a pull-down of the
      // notification shade makes the app inactive, which is not leaving it.
      onHide: _lock.onBackgrounded,
      onShow: _lock.onResumed,
    );
    // Replays the outbox whenever a user is signed in, sync is on and the
    // device is online; it watches all three itself.
    unawaited(getIt<SyncEngine>().start());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  bool _isInStack(String routeName) =>
      _router.stack.any((page) => page.routeData.name == routeName);

  void _onAuthChanged(BuildContext context, AuthState state) {
    if (state.isAuthenticated) return;
    // Signed out, here or on another device (token revoked).
    _lock.reset();
    unawaited(_router.replaceAll([const SignInRoute()]));
  }

  void _onLockChanged(BuildContext context, AppLockState state) {
    if (!state.locked || !_auth.state.isAuthenticated) return;
    // The splash routes a cold start itself, under the lock if needed.
    if (_isInStack(SplashRoute.name) || _isInStack(LockRoute.name)) return;
    unawaited(_router.push(const LockRoute()));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _auth),
        BlocProvider<AppLockCubit>.value(value: _lock),
        BlocProvider<SyncCubit>.value(value: getIt<SyncCubit>()),
        // The current business and role, for every screen.
        BlocProvider<BusinessScopeCubit>.value(
          value: getIt<BusinessScopeCubit>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listenWhen: (p, c) => p.isAuthenticated != c.isAuthenticated,
            listener: _onAuthChanged,
          ),
          BlocListener<AppLockCubit, AppLockState>(
            listenWhen: (p, c) => p.locked != c.locked,
            listener: _onLockChanged,
          ),
        ],
        // Above MaterialApp so `.sp` resolves while the theme is built.
        child: AppScreenUtil(
          builder: (context) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: MaterialApp.router(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: AppConfig.showDebugBanner,
              theme: AppTheme.dark,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              routerConfig: _router.config(),
              builder: (context, child) => _LateWriteFailures(
                child: _SyncFrame(
                  onTap: () {
                    if (!_auth.state.isAuthenticated ||
                        _isInStack(SyncRoute.name) ||
                        _isInStack(LockRoute.name)) {
                      return;
                    }
                    unawaited(_router.push(const SyncRoute()));
                  },
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puts the sync banner above every route. While it shows, it owns the
/// status-bar inset, so the page below drops its own top padding.
class _SyncFrame extends StatelessWidget {
  const _SyncFrame({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = context.select<SyncCubit, SyncStatus>(
      (cubit) => cubit.state.status,
    );
    final showing = SyncStatusBanner.describe(status) != null;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          SyncStatusBanner(status: status, onTap: onTap),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: showing,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a snack bar for changes the UI already reported as saved but the
/// server later refused: configuration writes queued offline, and outbox
/// actions refused on replay. Sits inside `MaterialApp`, below its
/// `ScaffoldMessenger`.
class _LateWriteFailures extends StatefulWidget {
  const _LateWriteFailures({required this.child});

  final Widget child;

  @override
  State<_LateWriteFailures> createState() => _LateWriteFailuresState();
}

class _LateWriteFailuresState extends State<_LateWriteFailures> {
  StreamSubscription<AppException>? _subscription;
  StreamSubscription<SyncEvent>? _refusals;

  @override
  void initState() {
    super.initState();
    _subscription = getIt<LocalFirstWriter>().lateFailures.listen((error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        "A change made offline couldn't be saved: ${error.message}",
        kind: AppSnackBarKind.error,
      );
    });
    _refusals = getIt<SyncEngine>().events
        .where((event) => event.type == SyncEventType.failed)
        .listen((event) {
          if (!mounted) return;
          showAppSnackBar(
            context,
            "${event.entry.label} couldn't be applied: "
            '${event.entry.lastError?.message ?? 'refused'}',
            kind: AppSnackBarKind.error,
          );
        });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_refusals?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
