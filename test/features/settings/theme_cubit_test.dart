import 'package:business_ledger/features/settings/logic/theme_cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('follows the system until a choice is made', () async {
    final cubit = ThemeCubit(await prefsWith({}));
    expect(cubit.state, ThemeMode.system);
    await cubit.close();
  });

  test('a choice is applied and remembered for the next launch', () async {
    final prefs = await prefsWith({});
    final cubit = ThemeCubit(prefs);
    await cubit.select(ThemeMode.light);
    expect(cubit.state, ThemeMode.light);
    expect(ThemeCubit(prefs).state, ThemeMode.light);
    await cubit.close();
  });

  test('an unknown stored value falls back to the system', () async {
    final cubit = ThemeCubit(
      await prefsWith({ThemeCubit.prefsKey: 'sepia'}),
    );
    expect(cubit.state, ThemeMode.system);
    await cubit.close();
  });
}
