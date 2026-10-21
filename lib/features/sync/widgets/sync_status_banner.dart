import 'dart:async';

import 'package:business_ledger/core/sync/sync_status.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How urgent a banner is; its colour comes from the active palette.
enum SyncBannerTone {
  warning,
  error,
  info;

  Color colorIn(AppPalette palette) => switch (this) {
    warning => palette.warning,
    error => palette.error,
    info => palette.info,
  };
}

/// What the banner says for one [SyncStatus].
class SyncBannerInfo extends Equatable {
  const SyncBannerInfo(
    this.icon,
    this.tone,
    this.message, {
    this.spin = false,
  });

  final IconData icon;
  final SyncBannerTone tone;
  final String message;

  /// Turn the icon (syncing).
  final bool spin;

  @override
  List<Object?> get props => [icon, tone, message, spin];
}

/// A strip above every route that says where the user's changes are:
/// "Offline · 3 changes will sync", "Sync paused · 3 waiting", "Syncing…",
/// "1 action needs attention". Hidden when online, on and idle.
///
/// Placed above the whole app (see `App`), so it owns the status-bar inset
/// while visible. Tapping it opens the Sync screen.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({required this.status, this.onTap, super.key});

  final SyncStatus status;
  final VoidCallback? onTap;

  static String _changes(int count) =>
      count == 1 ? '1 change' : '$count changes';

  /// `null` when there is nothing to say.
  static SyncBannerInfo? describe(SyncStatus status) {
    final waiting = status.pendingCount;
    final failed = status.failedCount;
    if (!status.online) {
      return SyncBannerInfo(
        Icons.cloud_off_rounded,
        SyncBannerTone.warning,
        waiting > 0
            ? 'Offline · ${_changes(waiting)} will sync'
            : status.hasLocalChanges
            ? 'Offline · changes will sync'
            : 'Offline · showing saved data',
      );
    }
    if (!status.syncEnabled) {
      return SyncBannerInfo(
        Icons.sync_disabled_rounded,
        SyncBannerTone.warning,
        waiting > 0
            ? 'Sync paused · $waiting waiting'
            : 'Sync paused · changes stay on this device',
      );
    }
    if (failed > 0) {
      return SyncBannerInfo(
        Icons.error_outline_rounded,
        SyncBannerTone.error,
        failed == 1
            ? '1 action needs attention'
            : '$failed actions need attention',
      );
    }
    if (status.syncing) {
      return const SyncBannerInfo(
        Icons.sync_rounded,
        SyncBannerTone.info,
        'Syncing…',
        spin: true,
      );
    }
    if (waiting > 0) {
      return SyncBannerInfo(
        Icons.schedule_rounded,
        SyncBannerTone.info,
        '${_changes(waiting)} waiting to sync',
      );
    }
    if (status.hasLocalChanges) {
      return const SyncBannerInfo(
        Icons.sync_rounded,
        SyncBannerTone.info,
        'Syncing…',
        spin: true,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final info = describe(status);
    final topInset = MediaQuery.paddingOf(context).top;
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: info == null
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              button: onTap != null,
              child: Material(
                color: context.colors.surfaceRaised,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: context.colors.border),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg.w,
                      topInset + AppSpacing.sm.h,
                      AppSpacing.md.w,
                      AppSpacing.sm.h,
                    ),
                    child: Row(
                      children: [
                        _BannerIcon(info: info),
                        SizedBox(width: AppSpacing.sm.w),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.centerLeft,
                              children: [...previous, ?current],
                            ),
                            child: Text(
                              info.message,
                              key: ValueKey(info.message),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: context.colors.textPrimary),
                            ),
                          ),
                        ),
                        if (onTap != null)
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18.r,
                            color: context.colors.textTertiary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _BannerIcon extends StatefulWidget {
  const _BannerIcon({required this.info});

  final SyncBannerInfo info;

  @override
  State<_BannerIcon> createState() => _BannerIconState();
}

class _BannerIconState extends State<_BannerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_BannerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    // Tests and reduced-motion settings get a still icon.
    final animate =
        widget.info.spin &&
        !WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    if (animate && !_spin.isAnimating) {
      unawaited(_spin.repeat());
    } else if (!animate && _spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    // Material's sync arrows turn anticlockwise.
    turns: ReverseAnimation(_spin),
    child: Icon(
      widget.info.icon,
      size: 16.r,
      color: widget.info.tone.colorIn(context.colors),
    ),
  );
}
