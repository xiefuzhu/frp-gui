import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式本地存储
class ThemeStorage {
  static const String _themeModeKey = 'theme_mode';

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);

    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

/// 主题色本地存储
class ColorStorage {
  static const String _colorKey = 'theme_color';

  static Future<void> saveColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.toARGB32());
  }

  static Future<Color> loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_colorKey);

    if (value == null) {
      return Colors.blue;
    }
    return Color(value);
  }
}
