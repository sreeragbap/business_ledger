import 'package:bloc/bloc.dart';

/// Makes a cubit that follows streams safe to close at any moment.
///
/// A cubit's `start` typically awaits cancelling its old subscription and
/// then subscribes again. If the screen closes during that await, `close()`
/// cancels the old subscription, and `start` then resumes and subscribes
/// after close: its next event calls `emit` on a closed cubit, which throws
/// `StateError: Cannot emit new states after calling close`.
///
/// Usage:
/// - call [beginClose] first thing in `close()` (before awaiting any
///   cancel; `isClosed` only turns true at the very end of `close()`);
/// - after each `await` that precedes a subscribe, `if (isClosing) return;`.
///
/// [emit] is also ignored once closing, so a late event is dropped instead
/// of crashing.
mixin CloseGuard<S> on BlocBase<S> {
  bool _closing = false;

  /// True from the moment `close()` starts.
  bool get isClosing => _closing || isClosed;

  void beginClose() => _closing = true;

  @override
  void emit(S state) {
    if (isClosing) return;
    super.emit(state);
  }
}
