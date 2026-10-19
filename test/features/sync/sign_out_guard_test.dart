import 'dart:async';

import 'package:business_ledger/core/domain/app_exception.dart';
import 'package:business_ledger/core/domain/app_result.dart';
import 'package:business_ledger/core/sync/outbox.dart';
import 'package:business_ledger/core/sync/outbox_entry.dart';
import 'package:business_ledger/core/sync/sync_engine.dart';
import 'package:business_ledger/core/sync/sync_settings.dart';
import 'package:business_ledger/features/sync/logic/sync_cubit/sync_cubit.dart';
import 'package:business_ledger/features/sync/widgets/sign_out_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sync/sync_fakes.dart';
import '../../support/screen.dart';

/// Sign-out is blocked while this user has actions in the outbox.
void main() {
  late FakeConnectivityService device;
  late FakeIdentity identity;
  late Outbox outbox;
  late FakeExecutor executor;
  late SyncEngine engine;
  late SyncCubit cubit;
  late List<bool> results;

  Future<void> build(
    WidgetTester tester, {
    List<OutboxEntry>? queued,
    bool online = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    device = FakeConnectivityService(isOnline: online);
    identity = FakeIdentity();
    outbox = Outbox(
      MemoryOutboxStore(
        queued ??
            [
              entry('pay'),
              entry('other', tx: 't2'),
              entry('theirs', uid: 'u2'),
            ],
      ),
    );
    executor = FakeExecutor();
    final settings = SyncSettings(await SharedPreferences.getInstance());
    engine = fakeEngine(
      outbox: outbox,
      executor: executor,
      device: device,
      settings: settings,
      identity: identity,
    );
    await engine.start();
    cubit = SyncCubit(engine, settings);
    results = [];
    await tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await confirmSignOutWithPending(context)),
            child: const Text('Sign out'),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openGuard(WidgetTester tester) async {
    await tester.tap(find.text('Sign out'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(SignOutBlockedDialog.title), findsOneWidget);
  }

  FilledButton syncNowButton(WidgetTester tester) => tester.widget(
    find.widgetWithText(FilledButton, 'Sync now'),
  );

  void dispose() {
    unawaited(cubit.close());
    unawaited(engine.dispose());
    unawaited(outbox.dispose());
    unawaited(device.dispose());
    unawaited(identity.dispose());
  }

  testWidgets('nothing waiting: no guard, sign-out may go ahead', (
    tester,
  ) async {
    await build(tester, queued: [entry('theirs', uid: 'u2')]);
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    expect(find.text(SignOutBlockedDialog.title), findsNothing);
    expect(results, [true]);
    dispose();
  });

  testWidgets('Cancel keeps the user signed in and the outbox intact', (
    tester,
  ) async {
    await build(tester);
    await openGuard(tester);
    expect(find.textContaining("2 changes haven't synced"), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(syncNowButton(tester).onPressed, isNull, reason: 'offline');

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(results, [false]);
    expect(outbox.entries, hasLength(3));
    dispose();
  });

  testWidgets('Sync now (once online) sends everything, then lets sign-out '
      'go ahead', (tester) async {
    // Reconnecting retries once and fails, so the guard is still needed.
    await build(tester);
    // The failure stops that pass, so 'other' is not tried either.
    executor.answer('pay', [const Failure(AppException.offline())]);
    await openGuard(tester);
    device.online = true;
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(SignOutBlockedDialog.title), findsOneWidget);
    expect(syncNowButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Sync now'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(executor.sentIds, ['pay', 'pay', 'other']);
    expect(find.text(SignOutBlockedDialog.title), findsNothing);
    expect(results, [true]);
    expect(outbox.entries.map((e) => e.id), ['theirs'], reason: 'not ours');
    dispose();
  });

  testWidgets('Discard and sign out asks again, then drops only this '
      "user's entries", (tester) async {
    await build(
      tester,
      queued: [
        entry('pay'),
        entry('cancel', kind: OutboxKind.cancel, tx: 't2'),
        entry('theirs', uid: 'u2'),
      ],
    );
    await openGuard(tester);
    await tester.tap(find.text('Discard and sign out'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Discard 2 changes?'), findsOneWidget);

    // Backing out of the second confirmation keeps everything.
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(results, [false]);
    expect(outbox.entries, hasLength(3));

    await openGuard(tester);
    await tester.tap(find.text('Discard and sign out'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.widgetWithText(FilledButton, 'Discard and sign out'),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(results, [false, true]);
    expect(outbox.entries.map((e) => e.id), ['theirs']);
    expect(executor.sent, isEmpty);
    dispose();
  });
}
