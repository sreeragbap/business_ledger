import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_fakes.dart';

void main() {
  late FakeNetwork network;

  setUp(() => network = FakeNetwork());

  Future<SyncSettings> settings([Map<String, Object> stored = const {}]) async {
    SharedPreferences.setMockInitialValues(stored);
    return SyncSettings(await SharedPreferences.getInstance(), network);
  }

  test('on by default; apply at startup enables the network', () async {
    final sync = await settings();
    expect(sync.enabled, isTrue);
    await sync.apply();
    expect(network.enables, 1);
    expect(network.disables, 0);
  });

  test('a stored "off" disables the network at startup', () async {
    final sync = await settings({SyncSettings.prefsKey: false});
    expect(sync.enabled, isFalse);
    await sync.apply();
    expect(network.disables, 1);
  });

  test('switching persists, announces and applies', () async {
    final sync = await settings();
    final seen = <bool>[];
    final subscription = sync.enabledChanges.listen(seen.add);
    await sync.setEnabled(value: false);
    await sync.setEnabled(value: false);
    await sync.setEnabled(value: true);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [true, false, true]);
    expect(network.disables, 1, reason: 'no-op when unchanged');
    expect(network.enables, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SyncSettings.prefsKey), isTrue);
    await subscription.cancel();
    await sync.dispose();
  });

  test('a failing SDK call does not undo the switch', () async {
    final failing = _FailingNetwork();
    SharedPreferences.setMockInitialValues({});
    final sync = SyncSettings(await SharedPreferences.getInstance(), failing);
    await sync.setEnabled(value: false);
    expect(sync.enabled, isFalse);
  });

  group('CloudAvailability', () {
    test('needs both a network and sync on', () async {
      final sync = await settings();
      final device = FakeConnectivityService();
      final cloud = CloudAvailability(device, sync);
      final seen = <bool>[];
      final subscription = cloud.onlineChanges.listen(seen.add);
      await settle();
      expect(cloud.isOnline, isTrue);

      await sync.setEnabled(value: false);
      await settle();
      expect(cloud.isOnline, isFalse);
      expect(await cloud.refresh(), isFalse);
      expect(cloud.unavailableError.message, AppException.syncOffMessage);

      await sync.setEnabled(value: true);
      device.online = false;
      await settle();
      expect(cloud.isOnline, isFalse);
      expect(cloud.unavailableError, const AppException.offline());

      device.online = true;
      await settle();
      expect(seen, [true, false, true, false, true]);
      await subscription.cancel();
      await device.dispose();
    });
  });
}

class _FailingNetwork extends FakeNetwork {
  @override
  Future<void> disable() => Future.error(StateError('terminated'));
}
