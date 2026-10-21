import 'package:business_ledger/core/widgets/app_exit_guard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen.dart';

void main() {
  late int exits;

  setUp(() => exits = 0);

  Future<void> pumpGuard(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpApp(const AppExitGuard(child: Text('home')));
  }

  /// The Android back button.
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
  }

  testWidgets('first back shows the hint, a second within 2 s exits', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pumpGuard(tester);

    await pressBack(tester);
    expect(find.text(AppExitGuard.message), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
    expect(exits, 0);

    await pressBack(tester);
    expect(exits, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a second back after the window only shows the hint again', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pumpGuard(tester);

    await pressBack(tester);
    await tester.pump(AppExitGuard.window + const Duration(milliseconds: 100));
    await pressBack(tester);
    expect(exits, 0);
    expect(find.text(AppExitGuard.message), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('does nothing on iOS (no system back button)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpGuard(tester);
    expect(find.byType(PopScope<Object?>), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
