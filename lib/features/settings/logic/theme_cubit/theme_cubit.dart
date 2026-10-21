import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The per-device appearance choice: follow the system, or always light or
/// dark (Settings › Appearance). `App` feeds it to `MaterialApp.themeMode`.
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const String prefsKey = 'appearance.themeMode';

  /// Unset or unknown follows the system.
  static ThemeMode _read(SharedPreferences prefs) {
    final stored = prefs.getString(prefsKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _prefs.setString(prefsKey, mode.name);
  }
}
