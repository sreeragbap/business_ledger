import 'package:business_ledger/core/bloc/status.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/widgets/app_empty_state.dart';
import 'package:business_ledger/core/widgets/app_error_state.dart';
import 'package:business_ledger/core/widgets/app_loader.dart';
import 'package:flutter/material.dart';

/// Renders one of loading / error / empty / data from a [Status] and the data
/// it produced, cross-fading between them.
///
/// Data wins over status: when [data] is already present a reload (status
/// loading) keeps showing it, and a failed refresh keeps the stale data on
/// screen — the caller shows the error as a snack bar instead. Only a first
/// load shows the full-screen loader or error.
class AppAsyncView<T> extends StatelessWidget {
  const AppAsyncView({
    required this.status,
    required this.data,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.onRetry,
    super.key,
  });

  final Status status;
  final T? data;
  final Widget Function(BuildContext context, T data) builder;

  /// Whether loaded [data] counts as empty (e.g. `(list) => list.isEmpty`).
  final bool Function(T data)? isEmpty;

  /// Shown for empty data. Defaults to a generic [AppEmptyState].
  final Widget? empty;

  /// Shown for a first load. Defaults to [AppLoader]; pass a skeleton for
  /// content with a known shape.
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final value = data;
    final Widget child;
    final String key;

    if (value != null) {
      if (isEmpty?.call(value) ?? false) {
        key = 'empty';
        child = empty ?? const AppEmptyState(title: 'Nothing here yet');
      } else {
        key = 'data';
        child = builder(context, value);
      }
    } else if (status.isFailure) {
      key = 'error';
      child = AppErrorState(message: status.message, onRetry: onRetry);
    } else {
      key = 'loading';
      child = loading ?? const AppLoader();
    }

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}
