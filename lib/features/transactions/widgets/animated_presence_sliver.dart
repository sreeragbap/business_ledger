import 'dart:async';

import 'package:business_ledger/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// A sliver list that animates rows in and out as [items] change: new keys
/// grow and fade in, vanished keys shrink and fade out where they were.
///
/// Implicit, like `AnimatedSwitcher` — the caller just passes the new list.
/// The first build and wholesale replacements (a new filter) do not animate,
/// and nothing animates when the platform asks for reduced motion.
class AnimatedPresenceSliver<T> extends StatefulWidget {
  const AnimatedPresenceSliver({
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    super.key,
  });

  final List<T> items;
  final Object Function(T item) keyOf;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<AnimatedPresenceSliver<T>> createState() =>
      _AnimatedPresenceSliverState<T>();
}

class _Slot<T> {
  _Slot(this.item, this.key, {this.entering = false, this.leaving = false});

  final T item;
  final Object key;
  bool entering;
  final bool leaving;
}

class _AnimatedPresenceSliverState<T> extends State<AnimatedPresenceSliver<T>> {
  late List<_Slot<T>> _slots = _fresh();
  Timer? _settle;

  List<_Slot<T>> _fresh() => [
    for (final item in widget.items) _Slot(item, widget.keyOf(item)),
  ];

  @override
  void didUpdateWidget(covariant AnimatedPresenceSliver<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.items, widget.items)) return;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final previous = _slots.where((slot) => !slot.leaving).toList();
    final previousKeys = {for (final slot in previous) slot.key};
    final nextKeys = {for (final item in widget.items) widget.keyOf(item)};
    final shared = previousKeys.intersection(nextKeys).length;
    // A wholesale change (new filter, first page) just swaps.
    if (reduceMotion || previous.isEmpty || shared == 0) {
      _slots = _fresh();
      return;
    }

    final result = <_Slot<T>>[
      for (final item in widget.items)
        _Slot(
          item,
          widget.keyOf(item),
          entering: !previousKeys.contains(widget.keyOf(item)),
        ),
    ];
    // Leaving rows stay where they were: after their nearest surviving
    // predecessor.
    for (var i = 0; i < previous.length; i++) {
      final slot = previous[i];
      if (nextKeys.contains(slot.key)) continue;
      var insertAt = 0;
      for (var j = i - 1; j >= 0; j--) {
        final index = result.indexWhere((s) => s.key == previous[j].key);
        if (index >= 0) {
          insertAt = index + 1;
          break;
        }
      }
      result.insert(insertAt, _Slot(slot.item, slot.key, leaving: true));
    }
    _slots = result;
    _settle?.cancel();
    _settle = Timer(AppMotion.slow + const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        _slots = [
          for (final slot in _slots)
            if (!slot.leaving) slot..entering = false,
        ];
      });
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indexOf = {
      for (var i = 0; i < _slots.length; i++) _slots[i].key: i,
    };
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final slot = _slots[index];
          return _Presence(
            key: ValueKey(slot.key),
            entering: slot.entering,
            leaving: slot.leaving,
            child: widget.itemBuilder(context, slot.item),
          );
        },
        childCount: _slots.length,
        findChildIndexCallback: (key) =>
            key is ValueKey ? indexOf[key.value] : null,
      ),
    );
  }
}

class _Presence extends StatefulWidget {
  const _Presence({
    required this.entering,
    required this.leaving,
    required this.child,
    super.key,
  });

  final bool entering;
  final bool leaving;
  final Widget child;

  @override
  State<_Presence> createState() => _PresenceState();
}

class _PresenceState extends State<_Presence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    value: widget.entering ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.emphasized,
  );

  @override
  void initState() {
    super.initState();
    if (widget.entering) unawaited(_controller.forward());
    if (widget.leaving) unawaited(_controller.reverse());
  }

  @override
  void didUpdateWidget(covariant _Presence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leaving && !oldWidget.leaving) {
      unawaited(_controller.reverse());
    } else if (!widget.leaving && oldWidget.leaving) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _curve,
    alignment: Alignment.topCenter,
    child: FadeTransition(
      opacity: _curve,
      child: IgnorePointer(ignoring: widget.leaving, child: widget.child),
    ),
  );
}
