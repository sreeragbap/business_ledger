import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/sync/cloud_availability.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sync_fakes.dart';

void main() {
  Future<SyncSettings> settings([Map<String, Object> stored = const {}]) async {
    SharedPreferences.setMockInitialValues(stored);
    return SyncSettings(await SharedPreferences.getInstance());
  }

  test('on by default; a stored "off" is read back', () async {
    expect((await settings()).enabled, isTrue);
    expect((await settings({SyncSettings.prefsKey: false})).enabled, isFalse);
  });

  test('switching persists and announces, once per change', () async {
    final sync = await settings();
    final seen = <bool>[];
    final subscription = sync.enabledChanges.listen(seen.add);
    await sync.setEnabled(value: false);
    await sync.setEnabled(value: false);
    await sync.setEnabled(value: true);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [true, false, true]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SyncSettings.prefsKey), isTrue);
    await subscription.cancel();
    await sync.dispose();
  });

  group('CloudAvailability', () {
    test('needs a network, sync on and someone signed in', () async {
      final sync = await settings();
      final device = FakeConnectivityService();
      final identity = FakeIdentity();
      final cloud = CloudAvailability(device, sync, identity);
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
      expect(cloud.isOnline, isTrue);

      identity.current = null;
      await settle();
      expect(cloud.isOnline, isFalse);
      expect(await cloud.refresh(), isFalse);
      expect(cloud.unavailableError.kind, AppErrorKind.unauthenticated);

      identity.current = 'u1';
      await settle();
      expect(seen, [true, false, true, false, true, false, true]);
      await subscription.cancel();
      await device.dispose();
      await identity.dispose();
    });
  });
}
