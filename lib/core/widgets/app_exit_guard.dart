import 'dart:async';

import 'package:business_ledger/core/widgets/app_snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android's "press back again to exit" on the app's root screen: the first
/// back press shows a hint, a second one within [window] closes the app.
///
/// iOS has no system back button, so there it does nothing.
class AppExitGuard extends StatefulWidget {
  const AppExitGuard({required this.child, super.key});

  final Widget child;

  /// How long the second press has to come.
  static const Duration window = Duration(seconds: 2);

  static const String message = 'Press back again to exit';

  @override
  State<AppExitGuard> createState() => _AppExitGuardState();
}

class _AppExitGuardState extends State<AppExitGuard> {
  /// Running while a second press would exit.
  Timer? _window;

  void _onBack(bool didPop, Object? _) {
    if (didPop) return;
    if (_window?.isActive ?? false) {
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      unawaited(SystemNavigator.pop());
      return;
    }
    _window = Timer(AppExitGuard.window, () {});
    showAppSnackBar(
      context,
      AppExitGuard.message,
      duration: AppExitGuard.window,
    );
  }

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) return widget.child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: widget.child,
    );
  }
}
