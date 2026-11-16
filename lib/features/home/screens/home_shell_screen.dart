import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:business_ledger/core/router/app_router.dart';
import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:business_ledger/core/theme/app_palette.dart';
import 'package:business_ledger/core/theme/app_radius.dart';
import 'package:business_ledger/core/theme/app_spacing.dart';
import 'package:business_ledger/core/widgets/app_exit_guard.dart';
import 'package:business_ledger/features/business/logic/business_scope_cubit/business_scope_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The signed-in shell: four tabs under a bottom navigation bar. Each tab
/// keeps its own state while another is showing.
///
/// Everything inside works on the current business, so the shell watches
/// `BusinessScopeCubit`: if the selection is dropped (the user left or was
/// removed, the business is gone) it hands over to the business picker.
/// Switching business replaces the whole shell (see `openBusiness`), so no
/// tab ever shows one business's data under another's name.
@RoutePage()
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  static const List<_Tab> _tabs = [
    _Tab('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard),
    _Tab('Transactions', Icons.receipt_long_outlined, Icons.receipt_long),
    _Tab('Reports', Icons.insert_chart_outlined, Icons.insert_chart),
    _Tab('Settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    // Reached without the splash (a restored route, say): resolve now.
    final scope = context.read<BusinessScopeCubit>();
    if (scope.state.status == ScopeStatus.initial) {
      unawaited(scope.restore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessScopeCubit, BusinessScopeState>(
      listenWhen: (previous, current) =>
          previous.status != ScopeStatus.none &&
          current.status == ScopeStatus.none,
      listener: (context, _) => unawaited(
        context.router.root.replaceAll([const BusinessPickerRoute()]),
      ),
      // Back on another tab returns to the dashboard (homeIndex); back on
      // the dashboard asks for a second press before leaving the app.
      child: AppExitGuard(
        child: AutoTabsRouter(
          homeIndex: 0,
          routes: const [
            DashboardRoute(),
            TransactionsRoute(),
            ReportsRoute(),
            SettingsRoute(),
          ],
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          transitionBuilder: (context, child, animation) =>
              FadeTransition(opacity: animation, child: child),
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);
            return Scaffold(
              body: child,
              bottomNavigationBar: _GlassNavBar(
                tabs: _tabs,
                selectedIndex: tabsRouter.activeIndex,
                onSelected: tabsRouter.setActiveIndex,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// A floating glass pill holding the tabs.
///
/// Tap a tab, or drag along the bar: the lit pill follows the finger, icon
/// and label colours blend as it passes each tab, a light haptic ticks at
/// every tab it crosses, and letting go snaps to the nearest tab. The pill
/// slides through the tabs in between instead of jumping.
class _GlassNavBar extends StatefulWidget {
  const _GlassNavBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Tab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<_GlassNavBar>
    with SingleTickerProviderStateMixin {
  static const double _inset = 5;

  /// Movement (logical px) before a touch counts as a drag, not a tap.
  static const double _dragThreshold = 4;

  /// A one-tab slide; longer jumps add per-tab time, up to a cap, so the
  /// pill moves at a steady speed through the tabs between.
  static const int _baseMs = 160;
  static const int _perSlotMs = 50;
  static const int _maxMs = 340;

  late final AnimationController _ctrl;
  late final CurvedAnimation _curve;

  /// Endpoints of the slide in flight, in tab units.
  double _from = 0;
  double _to = 0;

  /// While dragging, the pill's position under the finger (tab units).
  double? _dragPos;
  double _downX = 0;
  bool _dragging = false;

  /// The tab under the pill when the last haptic fired.
  int _hapticSlot = 0;

  int get _maxSlot => widget.tabs.length - 1;

  /// Where the pill is drawn this frame, in tab units.
  double get _pos => _dragPos ?? _from + (_to - _from) * _curve.value;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, value: 1);
    _curve = CurvedAnimation(parent: _ctrl, curve: AppMotion.standard);
    _from = _to = widget.selectedIndex.toDouble();
    _hapticSlot = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant _GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab can also change from outside (back returns to the
    // dashboard); follow it unless a finger is on the bar.
    if (!_dragging && oldWidget.selectedIndex != widget.selectedIndex) {
      _slideTo(widget.selectedIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _slideTo(double target) {
    final current = _pos;
    _dragPos = null;
    if ((current - target).abs() < 0.001 && !_ctrl.isAnimating) {
      _from = _to = target;
      _ctrl.value = 1;
      return;
    }
    final ms = (_baseMs + (current - target).abs() * _perSlotMs)
        .clamp(_baseMs, _maxMs)
        .round();
    _from = current;
    _to = target;
    _ctrl.duration = Duration(milliseconds: ms);
    unawaited(_ctrl.forward(from: 0));
  }

  int _slotAt(double x, double slotWidth) =>
      (x / slotWidth).floor().clamp(0, _maxSlot);

  void _select(int slot) {
    if (slot != widget.selectedIndex) {
      unawaited(HapticFeedback.selectionClick());
    }
    _hapticSlot = slot;
    widget.onSelected(slot);
  }

  void _onDown(PointerDownEvent e, double slotWidth) {
    _downX = e.localPosition.dx;
    _dragging = false;
    // Preview: start sliding towards the touched tab straight away.
    setState(() => _slideTo(_slotAt(_downX, slotWidth).toDouble()));
  }

  void _onMove(PointerMoveEvent e, double slotWidth) {
    final x = e.localPosition.dx;
    if (!_dragging && (x - _downX).abs() > _dragThreshold) {
      _dragging = true;
      _ctrl.stop();
    }
    if (!_dragging) return;
    // Keep the pill's centre under the finger.
    final pos = (x / slotWidth - 0.5).clamp(0.0, _maxSlot.toDouble());
    final slot = pos.round();
    if (slot != _hapticSlot) {
      _hapticSlot = slot;
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() => _dragPos = pos);
  }

  void _onUp(PointerUpEvent e, double slotWidth) {
    final slot = _dragging
        ? (_dragPos ?? _pos).round().clamp(0, _maxSlot)
        : _slotAt(e.localPosition.dx, slotWidth);
    _dragging = false;
    setState(() => _slideTo(slot.toDouble()));
    if (slot != widget.selectedIndex) {
      // The drag already ticked at each tab; a tap ticks once here.
      if (_hapticSlot != slot) unawaited(HapticFeedback.selectionClick());
      _hapticSlot = slot;
      widget.onSelected(slot);
    }
  }

  void _onCancel() {
    _dragging = false;
    _hapticSlot = widget.selectedIndex;
    setState(() => _slideTo(widget.selectedIndex.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;
    final height = 64.h.clamp(60.0, 72.0);

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal.w,
          AppSpacing.xs.h,
          AppSpacing.screenHorizontal.w,
          AppSpacing.xs.h,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.glass,
            borderRadius: AppRadius.chip,
            border: Border.all(color: colors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x66000000) : colors.glow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.all(_inset),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth = constraints.maxWidth / widget.tabs.length;
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _onDown(e, slotWidth),
                    onPointerMove: (e) => _onMove(e, slotWidth),
                    onPointerUp: (e) => _onUp(e, slotWidth),
                    onPointerCancel: (_) => _onCancel(),
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) =>
                          _content(context, slotWidth, isDark),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, double slotWidth, bool isDark) {
    final colors = context.colors;
    final pos = _pos.clamp(0.0, _maxSlot.toDouble());
    return Stack(
      children: [
        Positioned(
          left: pos * slotWidth,
          top: 0,
          bottom: 0,
          width: slotWidth,
          child: AnimatedScale(
            // The pill swells a little while it is being dragged.
            scale: _dragging ? 1.06 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.chip,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF2E4C78), Color(0xFF1B2D4C)]
                      : [
                          colors.accentMuted,
                          colors.accent.withValues(alpha: 0.06),
                        ],
                ),
                boxShadow: [BoxShadow(color: colors.glow, blurRadius: 16)],
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              Expanded(
                child: _GlassNavItem(
                  tab: widget.tabs[i],
                  selected: i == widget.selectedIndex,
                  // 1 with the pill centred on this tab, 0 a tab or more away.
                  selectionT: (1 - (i - pos).abs()).clamp(0.0, 1.0),
                  onSemanticTap: () => _select(i),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.tab,
    required this.selected,
    required this.selectionT,
    required this.onSemanticTap,
  });

  final _Tab tab;
  final bool selected;
  final double selectionT;

  /// Screen readers activate the tab here; touches go through the bar's
  /// pointer handling.
  final VoidCallback onSemanticTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colour = Color.lerp(
      colors.textTertiary,
      colors.textPrimary,
      selectionT,
    )!;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      onTap: onSemanticTap,
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1 + 0.08 * selectionT,
            child: Icon(
              selectionT >= 0.5 ? tab.selectedIcon : tab.icon,
              size: 22,
              color: colour,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: colour,
              fontWeight: selectionT >= 0.5 ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
