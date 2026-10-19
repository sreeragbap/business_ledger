import 'dart:io';

import 'package:business_ledger/core/database/local_store.dart';
import 'package:business_ledger/core/database/sync_table.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/profile_sync.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_puller.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_backend.dart';
import 'sync_fakes.dart';

void main() {
  late FakeRemoteTables remote;
  late LocalStore store;
  late ProfileSync profiles;

  setUp(() {
    remote = FakeRemoteTables();
    store = memoryStore();
    profiles = ProfileSync(store, remote);
  });

  tearDown(() => store.db.close());

  test(
    'sign-in upserts the profile: id, name and photo; never the email',
    () async {
      await profiles.saveSignIn(
        uid: 'u1',
        displayName: ' Asha ',
        photoUrl: 'https://x/p.png',
      );
      final result = await profiles.push('u1');
      expect(result.isSuccess, isTrue);
      expect(remote.calls, ['upsert profiles']);
      expect(remote.rows('profiles').single, {
        'id': 'u1',
        'display_name': 'Asha',
        'photo_url': 'https://x/p.png',
        'seq': 1,
      });
      final local = await store.readRow(SyncTable.profiles, {'id': 'u1'});
      expect(local!['local_pending'], isFalse);

      remote.calls.clear();
      await profiles.push('u1');
      expect(remote.calls, isEmpty, reason: 'nothing new to send');
    },
  );

  test("sign-in claims the store: another user's data is gone first", () async {
    await store.claimFor('u0');
    await store.upsertRows(SyncTable.businesses, [
      {'id': 'b1', 'name': 'Theirs'},
    ]);
    await profiles.saveSignIn(uid: 'u1');
    expect(await store.businessIds(), isEmpty);
  });

  test(
    'offline: stays pending; the last business goes with the next push',
    () async {
      await profiles.saveSignIn(uid: 'u1', displayName: 'Asha');
      remote.failNext = const SocketException('down');
      expect((await profiles.push('u1')).errorOrNull?.isOffline, isTrue);
      await profiles.saveLastBusiness('u1', 'b9');
      expect(await profiles.lastBusinessId('u1'), 'b9');

      await profiles.push('u1');
      expect(remote.rows('profiles').single['last_business_id'], 'b9');
      expect(remote.rows('profiles').single['display_name'], 'Asha');
    },
  );

  test('the sync engine pushes a pending profile before pulling', () async {
    SharedPreferences.setMockInitialValues({});
    await profiles.saveSignIn(uid: 'u1', displayName: 'Asha');
    final outbox = Outbox(MemoryOutboxStore());
    final engine = SyncEngine(
      outbox,
      FakeExecutor(),
      FakeConnectivityService(),
      SyncSettings(await SharedPreferences.getInstance()),
      FakeIdentity(),
      SyncPuller(remote, store),
      store,
      profiles,
      timer: FakeTimers().call,
      pullTimer: FakeTimers().call,
    );
    await engine.start();
    await settle();
    expect(remote.calls.take(2), ['upsert profiles', 'select profiles']);
    await engine.dispose();
    await outbox.dispose();
  });
}
