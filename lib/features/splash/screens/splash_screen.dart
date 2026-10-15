import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/di/injection.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_loader.dart';
import 'package:business_ledger/core/widgets/app_logo.dart';
import 'package:business_ledger/features/app_lock/logic/app_lock_cubit/app_lock_cubit.dart';
import 'package:business_ledger/features/auth/domain/repository/auth_repository.dart';
import 'package:business_ledger/features/business/logic/business_landing.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Decides where a cold start lands: sign-in, the home shell on the last
/// business, or the business picker (under the lock screen when app lock is
/// on).
@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Long enough for the mark to register, short enough not to be a wait.
  static const Duration _minimumShown = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    unawaited(_route());
  }

  Future<void> _route() async {
    final results = await Future.wait<Object?>([
      // The first event is authoritative; `currentUser` can lag a frame.
      getIt<AuthRepository>().userChanges.first,
      Future<void>.delayed(_minimumShown),
    ]);
    if (!mounted) return;

    final router = context.router;
    if (results.first == null) {
      await router.replaceAll([const SignInRoute()]);
      return;
    }

    final lock = getIt<AppLockCubit>()..lockOnColdStart();
    final landing = await businessLanding(getIt<BusinessScopeCubit>());
    if (!mounted) return;
    await router.replaceAll([
      landing,
      if (lock.state.locked) const LockRoute(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(),
            SizedBox(height: AppSpacing.xxxl.h),
            AppLoader(size: 20.r, center: false),
          ],
        ),
      ),
    );
  }
}
