import 'dart:async';

import 'package:business_ledger/core/widgets/app_confirm_dialog.dart';
import 'package:flutter/material.dart';

/// Asks before leaving a form with unsaved input: the back button, the back
/// gesture and the app bar's back arrow all go through it.
///
/// [hasChanges] comes from the last build. [hasChangesNow], when given, is
/// read again at the moment of leaving, for flows where the state moves on
/// between builds (a save that pops the page in the same frame).
class AppDiscardGuard extends StatelessWidget {
  const AppDiscardGuard({
    required this.hasChanges,
    required this.child,
    this.hasChangesNow,
    this.title = 'Discard changes?',
    this.message = 'What you entered will be lost.',
    super.key,
  });

  final bool hasChanges;
  final bool Function()? hasChangesNow;
  final String title;
  final String message;
  final Widget child;

  Future<void> _confirmLeave(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (!(hasChangesNow?.call() ?? true)) {
      navigator.pop();
      return;
    }
    final discard = await showAppConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      destructive: true,
    );
    // Navigator.pop skips PopScope, which would otherwise ask again.
    if (discard && navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !hasChanges,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_confirmLeave(context));
    },
    child: child,
  );
}
