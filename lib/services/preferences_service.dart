import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferencesSnapshot {
  final ThemeMode themeMode;
  final bool followSystemColor;
  final Color? customColor;

  const ThemePreferencesSnapshot({
    required this.themeMode,
    required this.followSystemColor,
    this.customColor,
  });
}

class PreferencesService {
  PreferencesService._();
  static final PreferencesService instance = PreferencesService._();

  static const String _themeModeKey = 'app_theme_mode';
  static const String _legacyThemeModeKey = 'theme_mode';
  static const String _colorValueKey = 'app_theme_color';
  static const String _legacyColorValueKey = 'theme_color';
  static const String _followSystemColorKey = 'app_follow_system_color';
  static const String _oobeCompletedKey = 'oobe_completed';

  Future<ThemePreferencesSnapshot> loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    var mode = ThemeMode.system;
    final savedModeIndex = prefs.getInt(_themeModeKey);
    if (savedModeIndex != null &&
        savedModeIndex >= 0 &&
        savedModeIndex < ThemeMode.values.length) {
      mode = ThemeMode.values[savedModeIndex];
    } else {
      final legacyMode = prefs.getString(_legacyThemeModeKey);
      if (legacyMode == 'light') {
        mode = ThemeMode.light;
      } else if (legacyMode == 'dark') {
        mode = ThemeMode.dark;
      }
    }

    final followSystem = prefs.getBool(_followSystemColorKey) ?? true;
    final rawColor =
        prefs.getInt(_colorValueKey) ?? prefs.getInt(_legacyColorValueKey);

    return ThemePreferencesSnapshot(
      themeMode: mode,
      followSystemColor: followSystem,
      customColor: rawColor != null ? Color(rawColor) : null,
    );
  }

  Future<void> saveThemePreferences({
    required ThemeMode themeMode,
    required bool followSystemColor,
    required Color accentColor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, themeMode.index);
    await prefs.setBool(_followSystemColorKey, followSystemColor);
    await prefs.setInt(_colorValueKey, accentColor.toARGB32());
  }

  Future<bool> isOobeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_oobeCompletedKey) ?? false;
  }

  Future<void> setOobeCompleted([bool completed = true]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_oobeCompletedKey, completed);
  }
}
