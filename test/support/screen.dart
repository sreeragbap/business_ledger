import 'package:business_ledger/core/responsive/app_screen_util.dart';
import 'package:business_ledger/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension ScreenTester on WidgetTester {
  /// Pins the test surface to the design frame, so `.w` / `.sp` scale by 1.
  void useDesignScreen() {
    view
      ..physicalSize = AppScreenUtil.designSize
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  }

  /// Pumps [child] inside the app's scaling and dark theme.
  Future<void> pumpApp(Widget child) {
    useDesignScreen();
    return pumpWidget(
      AppScreenUtil(
        builder: (_) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: child),
        ),
      ),
    );
  }
}
