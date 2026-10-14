import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/router/app_router.gr.dart';
import 'package:business_ledger/core/router/app_transitions.dart';
import 'package:business_ledger/core/router/guards/auth_guard.dart';
import 'package:business_ledger/core/router/route_paths.dart';
import 'package:injectable/injectable.dart';

export 'package:business_ledger/core/router/app_router.gr.dart';
export 'package:business_ledger/core/router/route_paths.dart';

/// Application route table.
///
/// `replaceInRouteName` turns `SignInScreen` into `SignInRoute`, so screens
/// keep the `Screen` suffix while routes read as routes.
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
@lazySingleton
class AppRouter extends RootStackRouter {
  AppRouter(this._authGuard);

  final AuthGuard _authGuard;

  @override
  RouteType get defaultRouteType => RouteType.custom(
    transitionsBuilder: AppTransitions.fadeRise,
    duration: AppTransitions.duration,
    reverseDuration: AppTransitions.duration,
  );

  @override
  List<AutoRoute> get routes => <AutoRoute>[
    CustomRoute<void>(
      page: SplashRoute.page,
      path: RoutePaths.splash,
      initial: true,
      transitionsBuilder: AppTransitions.fade,
      duration: AppTransitions.duration,
    ),
    CustomRoute<void>(
      page: SignInRoute.page,
      path: RoutePaths.signIn,
      transitionsBuilder: AppTransitions.fade,
      duration: AppTransitions.duration,
    ),

    // Pushed over whatever is showing; fades so the content behind does not
    // visibly slide away.
    CustomRoute<void>(
      page: LockRoute.page,
      path: RoutePaths.lock,
      guards: <AutoRouteGuard>[_authGuard],
      transitionsBuilder: AppTransitions.fade,
      duration: AppTransitions.duration,
    ),

    CustomRoute<void>(
      page: BusinessPickerRoute.page,
      path: RoutePaths.businessPicker,
      guards: <AutoRouteGuard>[_authGuard],
      transitionsBuilder: AppTransitions.fadeRise,
      duration: AppTransitions.duration,
    ),

    // The tabbed shell. Everything inside needs a session, so the guard sits
    // on the parent rather than on each tab.
    CustomRoute<void>(
      page: HomeShellRoute.page,
      path: RoutePaths.home,
      guards: <AutoRouteGuard>[_authGuard],
      transitionsBuilder: AppTransitions.fade,
      duration: AppTransitions.duration,
      children: <AutoRoute>[
        AutoRoute(
          page: DashboardRoute.page,
          path: RoutePaths.dashboard,
          initial: true,
        ),
        AutoRoute(page: TransactionsRoute.page, path: RoutePaths.transactions),
        AutoRoute(page: ReportsRoute.page, path: RoutePaths.reports),
        AutoRoute(page: SettingsRoute.page, path: RoutePaths.settings),
      ],
    ),
  ];
}
