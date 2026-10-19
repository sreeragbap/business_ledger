import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/pending_writes_tracker.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:business_ledger/core/sync/sync_status.dart';
import 'package:business_ledger/features/sync/logic/sync_cubit/sync_cubit.dart';
import 'package:business_ledger/features/sync/screens/sync_screen.dart';
import 'package:business_ledger/features/sync/widgets/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_fakes.dart';
import '../../support/screen.dart';

void main() {
  group('SyncStatusBanner.describe', () {
    String? text(SyncStatus status) =>
        SyncStatusBanner.describe(status)?.message;

    test('hidden when online, on and idle', () {
      expect(text(const SyncStatus()), isNull);
    });

    test('offline counts what will sync', () {
      expect(
        text(const SyncStatus(online: false, pendingCount: 3)),
        'Offline · 3 changes will sync',
      );
      expect(
        text(const SyncStatus(online: false, pendingCount: 1)),
        'Offline · 1 change will sync',
      );
      expect(
        text(const SyncStatus(online: false, firestoreHasPendingWrites: true)),
        'Offline · changes will sync',
      );
      expect(
        text(const SyncStatus(online: false)),
        'Offline · showing saved data',
      );
    });

    test('sync off is "paused"', () {
      expect(
        text(const SyncStatus(syncEnabled: false, pendingCount: 3)),
        'Sync paused · 3 waiting',
      );
      expect(
        text(const SyncStatus(syncEnabled: false)),
        'Sync paused · changes stay on this device',
      );
    });

    test('refusals need attention; then syncing', () {
      expect(
        text(const SyncStatus(failedCount: 1, syncing: true)),
        '1 action needs attention',
      );
      expect(
        text(const SyncStatus(failedCount: 2)),
        '2 actions need attention',
      );
      expect(text(const SyncStatus(syncing: true)), 'Syncing…');
      expect(
        text(const SyncStatus(firestoreHasPendingWrites: true)),
        'Syncing…',
      );
      expect(
        text(const SyncStatus(pendingCount: 2)),
        '2 changes waiting to sync',
      );
    });
  });

  testWidgets('banner: slides in with the message, taps through, hides', (
    tester,
  ) async {
    var taps = 0;
    Widget banner(SyncStatus status) => Column(
      children: [
        SyncStatusBanner(status: status, onTap: () => taps++),
        const Expanded(child: SizedBox()),
      ],
    );
    await tester.pumpApp(banner(const SyncStatus()));
    expect(find.byType(InkWell), findsNothing);

    await tester.pumpApp(
      banner(const SyncStatus(online: false, pendingCount: 3)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Offline · 3 changes will sync'), findsOneWidget);
    await tester.tap(find.text('Offline · 3 changes will sync'));
    expect(taps, 1);

    await tester.pumpApp(banner(const SyncStatus(syncing: true)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Syncing…'), findsOneWidget);

    await tester.pumpApp(banner(const SyncStatus()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Syncing…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('Sync screen', () {
    late FakeNetwork network;
    late FakeConnectivityService device;
    late FakeIdentity identity;
    late Outbox outbox;
    late FakeExecutor executor;
    late PendingWritesTracker writes;
    late SyncSettings settings;
    late SyncEngine engine;
    late SyncCubit cubit;

    final refused = entry('pay').copyWith(
      status: OutboxStatus.failed,
      lastError: () =>
          const OutboxError(message: 'More than what is outstanding.'),
    );
    final dependent = entry('cancel', kind: OutboxKind.cancel);
    final waiting = entry('other', tx: 't2');

    Future<void> build(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      network = FakeNetwork();
      device = FakeConnectivityService(isOnline: false);
      identity = FakeIdentity();
      outbox = Outbox(MemoryOutboxStore([refused, dependent, waiting]));
      executor = FakeExecutor();
      writes = PendingWritesTracker();
      settings = SyncSettings(await SharedPreferences.getInstance(), network);
      final timers = FakeTimers();
      engine = SyncEngine(
        outbox,
        executor,
        network,
        device,
        settings,
        identity,
        writes,
        timer: timers.call,
      );
      await engine.start();
      cubit = SyncCubit(engine, settings);
      await tester.pumpApp(
        BlocProvider.value(value: cubit, child: const SyncView()),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> reveal(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 300));
    }

    void dispose() {
      unawaited(cubit.close());
      unawaited(engine.dispose());
      unawaited(outbox.dispose());
      unawaited(device.dispose());
      unawaited(identity.dispose());
      unawaited(writes.dispose());
    }

    testWidgets('shows the switch, status and the outbox with reasons', (
      tester,
    ) async {
      await build(tester);
      expect(
        find.widgetWithText(SwitchListTile, 'Cloud sync'),
        findsOneWidget,
      );
      expect(find.text('Offline · 2 changes will sync'), findsOneWidget);
      expect(find.text('Waiting for a connection.'), findsOneWidget);
      await reveal(tester, find.text('Retry'));
      expect(
        find.text('WAITING TO SYNC · 3', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text(refused.label), findsOneWidget);
      expect(find.text('More than what is outstanding.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget, reason: 'failed only');
      final syncNow = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Sync now'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(syncNow.onPressed, isNull, reason: 'offline');
      dispose();
    });

    testWidgets('turning sync off disables the network and says paused', (
      tester,
    ) async {
      await build(tester);
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 300));
      expect(network.disables, 1);
      expect(settings.enabled, isFalse);
      // Back online, but paused: nothing goes.
      device.online = true;
      await tester.pump(const Duration(milliseconds: 300));
      expect(executor.sent, isEmpty);
      expect(find.text('Sync paused · 2 waiting'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      dispose();
    });

    testWidgets('retry puts a refused action back in line', (tester) async {
      await build(tester);
      await reveal(tester, find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(outbox.byId('pay')!.status, OutboxStatus.pending);
      expect(find.text('Retry'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      dispose();
    });

    testWidgets('discard asks first, naming the dependent actions', (
      tester,
    ) async {
      await build(tester);
      await reveal(tester, find.text('Discard'));
      await tester.tap(find.text('Discard'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Discard this action?'), findsOneWidget);
      expect(find.textContaining(dependent.label), findsNWidgets(2));
      await tester.tap(find.widgetWithText(FilledButton, 'Discard').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(outbox.entries.map((e) => e.id), ['other']);
      await tester.pump(const Duration(seconds: 5));
      dispose();
    });

    testWidgets('online: "Sync now" sends what is waiting', (tester) async {
      await build(tester);
      executor.answer('other', [const Failure(AppException.offline())]);
      device.online = true;
      await tester.pump(const Duration(milliseconds: 300));
      // The reconnect itself retried; the refused one stays for the user.
      expect(executor.sentIds, ['other']);
      await reveal(tester, find.text('Sync now'));
      await tester.tap(find.text('Sync now'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(executor.sentIds, ['other', 'other']);
      expect(outbox.entries.map((e) => e.id), ['pay', 'cancel']);
      await tester.pump(const Duration(seconds: 5));
      dispose();
    });
  });
}
