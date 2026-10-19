import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The per-device "Cloud sync" switch (default on).
///
/// Off, the app works entirely from this device: the sync engine neither
/// pushes the outbox nor pulls, and online-only actions are refused.
/// Everything changed meanwhile waits in the outbox until it is switched
/// back on.
@lazySingleton
class SyncSettings {
  SyncSettings(this._prefs);

  final SharedPreferences _prefs;
  late final BehaviorSubject<bool> _changes = BehaviorSubject<bool>.seeded(
    enabled,
  );

  static const String prefsKey = 'sync.cloudEnabled';
  static const String lastSyncedKey = 'sync.lastSyncedAt';

  bool get enabled => _prefs.getBool(prefsKey) ?? true;

  /// When this device last finished a push or pull with the server.
  DateTime? get lastSyncedAt {
    final millis = _prefs.getInt(lastSyncedKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastSyncedAt(DateTime value) =>
      _prefs.setInt(lastSyncedKey, value.millisecondsSinceEpoch);

  /// The current value first, then each change.
  Stream<bool> get enabledChanges => _changes.stream;

  /// Stores [value]; the sync engine reacts to [enabledChanges].
  Future<void> setEnabled({required bool value}) async {
    if (value == enabled) return;
    await _prefs.setBool(prefsKey, value);
    if (!_changes.isClosed) _changes.add(value);
  }

  @disposeMethod
  Future<void> dispose() => _changes.close();
}
