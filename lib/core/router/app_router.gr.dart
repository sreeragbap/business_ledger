// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i21;
import 'package:business_ledger/core/ledger/ledger_enums.dart' as _i23;
import 'package:business_ledger/features/app_lock/screens/lock_screen.dart'
    as _i8;
import 'package:business_ledger/features/auth/screens/sign_in_screen.dart'
    as _i14;
import 'package:business_ledger/features/business/screens/business_details_screen.dart'
    as _i1;
import 'package:business_ledger/features/business/screens/business_picker_screen.dart'
    as _i2;
import 'package:business_ledger/features/business/screens/create_business_screen.dart'
    as _i4;
import 'package:business_ledger/features/business/screens/members_screen.dart'
    as _i9;
import 'package:business_ledger/features/categories/screens/categories_screen.dart'
    as _i3;
import 'package:business_ledger/features/categories/screens/custom_fields_screen.dart'
    as _i5;
import 'package:business_ledger/features/dashboard/screens/dashboard_screen.dart'
    as _i6;
import 'package:business_ledger/features/home/screens/home_shell_screen.dart'
    as _i7;
import 'package:business_ledger/features/parties/screens/parties_screen.dart'
    as _i10;
import 'package:business_ledger/features/projects/screens/projects_screen.dart'
    as _i11;
import 'package:business_ledger/features/reports/screens/reports_screen.dart'
    as _i12;
import 'package:business_ledger/features/settings/screens/settings_screen.dart'
    as _i13;
import 'package:business_ledger/features/splash/screens/splash_screen.dart'
    as _i15;
import 'package:business_ledger/features/transactions/domain/models/transaction_filter.dart'
    as _i19;
import 'package:business_ledger/features/transactions/screens/transaction_detail_screen.dart'
    as _i16;
import 'package:business_ledger/features/transactions/screens/transaction_form_screen.dart'
    as _i17;
import 'package:business_ledger/features/transactions/screens/transaction_list_screen.dart'
    as _i18;
import 'package:business_ledger/features/transactions/screens/transactions_screen.dart'
    as _i20;
import 'package:flutter/material.dart' as _i22;

/// generated route for
/// [_i1.BusinessDetailsScreen]
class BusinessDetailsRoute extends _i21.PageRouteInfo<void> {
  const BusinessDetailsRoute({List<_i21.PageRouteInfo>? children})
    : super(BusinessDetailsRoute.name, initialChildren: children);

  static const String name = 'BusinessDetailsRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i1.BusinessDetailsScreen());
    },
  );
}

/// generated route for
/// [_i2.BusinessPickerScreen]
class BusinessPickerRoute extends _i21.PageRouteInfo<void> {
  const BusinessPickerRoute({List<_i21.PageRouteInfo>? children})
    : super(BusinessPickerRoute.name, initialChildren: children);

  static const String name = 'BusinessPickerRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i2.BusinessPickerScreen());
    },
  );
}

/// generated route for
/// [_i3.CategoriesScreen]
class CategoriesRoute extends _i21.PageRouteInfo<void> {
  const CategoriesRoute({List<_i21.PageRouteInfo>? children})
    : super(CategoriesRoute.name, initialChildren: children);

  static const String name = 'CategoriesRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i3.CategoriesScreen());
    },
  );
}

/// generated route for
/// [_i4.CreateBusinessScreen]
class CreateBusinessRoute extends _i21.PageRouteInfo<void> {
  const CreateBusinessRoute({List<_i21.PageRouteInfo>? children})
    : super(CreateBusinessRoute.name, initialChildren: children);

  static const String name = 'CreateBusinessRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i4.CreateBusinessScreen());
    },
  );
}

/// generated route for
/// [_i5.CustomFieldsScreen]
class CustomFieldsRoute extends _i21.PageRouteInfo<void> {
  const CustomFieldsRoute({List<_i21.PageRouteInfo>? children})
    : super(CustomFieldsRoute.name, initialChildren: children);

  static const String name = 'CustomFieldsRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i5.CustomFieldsScreen());
    },
  );
}

/// generated route for
/// [_i6.DashboardScreen]
class DashboardRoute extends _i21.PageRouteInfo<void> {
  const DashboardRoute({List<_i21.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i6.DashboardScreen());
    },
  );
}

/// generated route for
/// [_i7.HomeShellScreen]
class HomeShellRoute extends _i21.PageRouteInfo<void> {
  const HomeShellRoute({List<_i21.PageRouteInfo>? children})
    : super(HomeShellRoute.name, initialChildren: children);

  static const String name = 'HomeShellRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i7.HomeShellScreen();
    },
  );
}

/// generated route for
/// [_i8.LockScreen]
class LockRoute extends _i21.PageRouteInfo<void> {
  const LockRoute({List<_i21.PageRouteInfo>? children})
    : super(LockRoute.name, initialChildren: children);

  static const String name = 'LockRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i8.LockScreen());
    },
  );
}

/// generated route for
/// [_i9.MembersScreen]
class MembersRoute extends _i21.PageRouteInfo<void> {
  const MembersRoute({List<_i21.PageRouteInfo>? children})
    : super(MembersRoute.name, initialChildren: children);

  static const String name = 'MembersRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i9.MembersScreen());
    },
  );
}

/// generated route for
/// [_i10.PartiesScreen]
class PartiesRoute extends _i21.PageRouteInfo<void> {
  const PartiesRoute({List<_i21.PageRouteInfo>? children})
    : super(PartiesRoute.name, initialChildren: children);

  static const String name = 'PartiesRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i10.PartiesScreen());
    },
  );
}

/// generated route for
/// [_i11.ProjectsScreen]
class ProjectsRoute extends _i21.PageRouteInfo<void> {
  const ProjectsRoute({List<_i21.PageRouteInfo>? children})
    : super(ProjectsRoute.name, initialChildren: children);

  static const String name = 'ProjectsRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i11.ProjectsScreen());
    },
  );
}

/// generated route for
/// [_i12.ReportsScreen]
class ReportsRoute extends _i21.PageRouteInfo<void> {
  const ReportsRoute({List<_i21.PageRouteInfo>? children})
    : super(ReportsRoute.name, initialChildren: children);

  static const String name = 'ReportsRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i12.ReportsScreen());
    },
  );
}

/// generated route for
/// [_i13.SettingsScreen]
class SettingsRoute extends _i21.PageRouteInfo<void> {
  const SettingsRoute({List<_i21.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i13.SettingsScreen());
    },
  );
}

/// generated route for
/// [_i14.SignInScreen]
class SignInRoute extends _i21.PageRouteInfo<void> {
  const SignInRoute({List<_i21.PageRouteInfo>? children})
    : super(SignInRoute.name, initialChildren: children);

  static const String name = 'SignInRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i14.SignInScreen());
    },
  );
}

/// generated route for
/// [_i15.SplashScreen]
class SplashRoute extends _i21.PageRouteInfo<void> {
  const SplashRoute({List<_i21.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i15.SplashScreen();
    },
  );
}

/// generated route for
/// [_i16.TransactionDetailScreen]
class TransactionDetailRoute
    extends _i21.PageRouteInfo<TransactionDetailRouteArgs> {
  TransactionDetailRoute({
    required String transactionId,
    _i22.Key? key,
    List<_i21.PageRouteInfo>? children,
  }) : super(
         TransactionDetailRoute.name,
         args: TransactionDetailRouteArgs(
           transactionId: transactionId,
           key: key,
         ),
         rawPathParams: {'transactionId': transactionId},
         initialChildren: children,
       );

  static const String name = 'TransactionDetailRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TransactionDetailRouteArgs>(
        orElse: () => TransactionDetailRouteArgs(
          transactionId: pathParams.getString('transactionId'),
        ),
      );
      return _i21.WrappedRoute(
        child: _i16.TransactionDetailScreen(
          transactionId: args.transactionId,
          key: args.key,
        ),
      );
    },
  );
}

class TransactionDetailRouteArgs {
  const TransactionDetailRouteArgs({required this.transactionId, this.key});

  final String transactionId;

  final _i22.Key? key;

  @override
  String toString() {
    return 'TransactionDetailRouteArgs{transactionId: $transactionId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransactionDetailRouteArgs) return false;
    return transactionId == other.transactionId && key == other.key;
  }

  @override
  int get hashCode => transactionId.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i17.TransactionFormScreen]
class TransactionFormRoute
    extends _i21.PageRouteInfo<TransactionFormRouteArgs> {
  TransactionFormRoute({
    String? transactionId,
    _i23.TransactionType? initialType,
    _i22.Key? key,
    List<_i21.PageRouteInfo>? children,
  }) : super(
         TransactionFormRoute.name,
         args: TransactionFormRouteArgs(
           transactionId: transactionId,
           initialType: initialType,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TransactionFormRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TransactionFormRouteArgs>(
        orElse: () => const TransactionFormRouteArgs(),
      );
      return _i21.WrappedRoute(
        child: _i17.TransactionFormScreen(
          transactionId: args.transactionId,
          initialType: args.initialType,
          key: args.key,
        ),
      );
    },
  );
}

class TransactionFormRouteArgs {
  const TransactionFormRouteArgs({
    this.transactionId,
    this.initialType,
    this.key,
  });

  final String? transactionId;

  final _i23.TransactionType? initialType;

  final _i22.Key? key;

  @override
  String toString() {
    return 'TransactionFormRouteArgs{transactionId: $transactionId, initialType: $initialType, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransactionFormRouteArgs) return false;
    return transactionId == other.transactionId &&
        initialType == other.initialType &&
        key == other.key;
  }

  @override
  int get hashCode =>
      transactionId.hashCode ^ initialType.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i18.TransactionListScreen]
class TransactionListRoute
    extends _i21.PageRouteInfo<TransactionListRouteArgs> {
  TransactionListRoute({
    _i19.TransactionFilter initialFilter = const _i19.TransactionFilter(),
    String title = 'Transactions',
    _i22.Key? key,
    List<_i21.PageRouteInfo>? children,
  }) : super(
         TransactionListRoute.name,
         args: TransactionListRouteArgs(
           initialFilter: initialFilter,
           title: title,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TransactionListRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TransactionListRouteArgs>(
        orElse: () => const TransactionListRouteArgs(),
      );
      return _i21.WrappedRoute(
        child: _i18.TransactionListScreen(
          initialFilter: args.initialFilter,
          title: args.title,
          key: args.key,
        ),
      );
    },
  );
}

class TransactionListRouteArgs {
  const TransactionListRouteArgs({
    this.initialFilter = const _i19.TransactionFilter(),
    this.title = 'Transactions',
    this.key,
  });

  final _i19.TransactionFilter initialFilter;

  final String title;

  final _i22.Key? key;

  @override
  String toString() {
    return 'TransactionListRouteArgs{initialFilter: $initialFilter, title: $title, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransactionListRouteArgs) return false;
    return initialFilter == other.initialFilter &&
        title == other.title &&
        key == other.key;
  }

  @override
  int get hashCode => initialFilter.hashCode ^ title.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i20.TransactionsScreen]
class TransactionsRoute extends _i21.PageRouteInfo<void> {
  const TransactionsRoute({List<_i21.PageRouteInfo>? children})
    : super(TransactionsRoute.name, initialChildren: children);

  static const String name = 'TransactionsRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return _i21.WrappedRoute(child: const _i20.TransactionsScreen());
    },
  );
}
