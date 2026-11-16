import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Shrinks its child a touch while a finger is down, then springs back.
/// Purely visual: it never handles the tap, so the child's own button or
/// InkWell still decides what a tap does.
class AppPressable extends StatefulWidget {
  const AppPressable({
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
    super.key,
  });

  final Widget child;

  /// Off for disabled controls, so they don't react to touches.
  final bool enabled;
  final double scale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && widget.enabled ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: _down ? AppMotion.standard : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
