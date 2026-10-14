// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i10;
import 'package:business_ledger/features/app_lock/screens/lock_screen.dart'
    as _i4;
import 'package:business_ledger/features/auth/screens/sign_in_screen.dart'
    as _i7;
import 'package:business_ledger/features/business/screens/business_picker_screen.dart'
    as _i1;
import 'package:business_ledger/features/dashboard/screens/dashboard_screen.dart'
    as _i2;
import 'package:business_ledger/features/home/screens/home_shell_screen.dart'
    as _i3;
import 'package:business_ledger/features/reports/screens/reports_screen.dart'
    as _i5;
import 'package:business_ledger/features/settings/screens/settings_screen.dart'
    as _i6;
import 'package:business_ledger/features/splash/screens/splash_screen.dart'
    as _i8;
import 'package:business_ledger/features/transactions/screens/transactions_screen.dart'
    as _i9;

/// generated route for
/// [_i1.BusinessPickerScreen]
class BusinessPickerRoute extends _i10.PageRouteInfo<void> {
  const BusinessPickerRoute({List<_i10.PageRouteInfo>? children})
    : super(BusinessPickerRoute.name, initialChildren: children);

  static const String name = 'BusinessPickerRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i1.BusinessPickerScreen();
    },
  );
}

/// generated route for
/// [_i2.DashboardScreen]
class DashboardRoute extends _i10.PageRouteInfo<void> {
  const DashboardRoute({List<_i10.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return _i10.WrappedRoute(child: const _i2.DashboardScreen());
    },
  );
}

/// generated route for
/// [_i3.HomeShellScreen]
class HomeShellRoute extends _i10.PageRouteInfo<void> {
  const HomeShellRoute({List<_i10.PageRouteInfo>? children})
    : super(HomeShellRoute.name, initialChildren: children);

  static const String name = 'HomeShellRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i3.HomeShellScreen();
    },
  );
}

/// generated route for
/// [_i4.LockScreen]
class LockRoute extends _i10.PageRouteInfo<void> {
  const LockRoute({List<_i10.PageRouteInfo>? children})
    : super(LockRoute.name, initialChildren: children);

  static const String name = 'LockRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return _i10.WrappedRoute(child: const _i4.LockScreen());
    },
  );
}

/// generated route for
/// [_i5.ReportsScreen]
class ReportsRoute extends _i10.PageRouteInfo<void> {
  const ReportsRoute({List<_i10.PageRouteInfo>? children})
    : super(ReportsRoute.name, initialChildren: children);

  static const String name = 'ReportsRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i5.ReportsScreen();
    },
  );
}

/// generated route for
/// [_i6.SettingsScreen]
class SettingsRoute extends _i10.PageRouteInfo<void> {
  const SettingsRoute({List<_i10.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return _i10.WrappedRoute(child: const _i6.SettingsScreen());
    },
  );
}

/// generated route for
/// [_i7.SignInScreen]
class SignInRoute extends _i10.PageRouteInfo<void> {
  const SignInRoute({List<_i10.PageRouteInfo>? children})
    : super(SignInRoute.name, initialChildren: children);

  static const String name = 'SignInRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return _i10.WrappedRoute(child: const _i7.SignInScreen());
    },
  );
}

/// generated route for
/// [_i8.SplashScreen]
class SplashRoute extends _i10.PageRouteInfo<void> {
  const SplashRoute({List<_i10.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i8.SplashScreen();
    },
  );
}

/// generated route for
/// [_i9.TransactionsScreen]
class TransactionsRoute extends _i10.PageRouteInfo<void> {
  const TransactionsRoute({List<_i10.PageRouteInfo>? children})
    : super(TransactionsRoute.name, initialChildren: children);

  static const String name = 'TransactionsRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i9.TransactionsScreen();
    },
  );
}
