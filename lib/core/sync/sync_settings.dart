import 'dart:async';
import 'dart:developer' as developer;

import 'package:business_ledger/core/sync/firestore_network.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The per-device "Cloud sync" switch (default on).
///
/// Off, the app works entirely from this device: Firestore's network is
/// disabled (reads from the cache, writes queue locally), and money actions
/// wait in the outbox. Nothing is sent until it is switched back on.
@lazySingleton
class SyncSettings {
  SyncSettings(this._prefs, this._network);

  final SharedPreferences _prefs;
  final FirestoreNetwork _network;
  late final BehaviorSubject<bool> _changes = BehaviorSubject<bool>.seeded(
    enabled,
  );

  static const String prefsKey = 'sync.cloudEnabled';
  static const String lastSyncedKey = 'sync.lastSyncedAt';

  bool get enabled => _prefs.getBool(prefsKey) ?? true;

  /// When the outbox last applied an entry on the server.
  DateTime? get lastSyncedAt {
    final millis = _prefs.getInt(lastSyncedKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastSyncedAt(DateTime value) =>
      _prefs.setInt(lastSyncedKey, value.millisecondsSinceEpoch);

  /// The current value first, then each change.
  Stream<bool> get enabledChanges => _changes.stream;

  /// Pushes the stored value to Firestore. Run once at startup, before the
  /// first screen reads anything.
  Future<void> apply() => _applyNetwork(enabled: enabled);

  /// Stores [value] and applies it. The stored value changes even if the
  /// SDK call fails: the switch is the user's intent, and [apply] runs again
  /// on the next start.
  Future<void> setEnabled({required bool value}) async {
    if (value == enabled) return;
    await _prefs.setBool(prefsKey, value);
    if (!_changes.isClosed) _changes.add(value);
    await _applyNetwork(enabled: value);
  }

  Future<void> _applyNetwork({required bool enabled}) async {
    try {
      await (enabled ? _network.enable() : _network.disable());
    } catch (error) {
      developer.log(
        'Could not ${enabled ? 'enable' : 'disable'} the Firestore network',
        name: 'sync',
        error: error,
      );
    }
  }

  @disposeMethod
  Future<void> dispose() => _changes.close();
}
