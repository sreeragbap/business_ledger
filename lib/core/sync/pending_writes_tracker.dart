import 'dart:async';

import 'package:injectable/injectable.dart';

/// Counts Firestore writes this session handed to the local queue without
/// a server acknowledgement yet (offline, sync off, or slow), as reported
/// by `LocalFirstWriter`. One input to `SyncStatus.firestoreHasPendingWrites`.
@lazySingleton
class PendingWritesTracker {
  final StreamController<int> _changes = StreamController<int>.broadcast();
  int _count = 0;

  int get count => _count;
  bool get hasPending => _count > 0;

  /// Each change of [count].
  Stream<int> get changes => _changes.stream;

  void begin() => _set(_count + 1);

  void end() => _set(_count > 0 ? _count - 1 : 0);

  void _set(int value) {
    if (value == _count) return;
    _count = value;
    if (!_changes.isClosed) _changes.add(value);
  }

  @disposeMethod
  Future<void> dispose() => _changes.close();
}
