import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//主题模式的本地存储类
class ThemeStorage {
  static const String themeModeKey = 'theme_mode';

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, mode.name);
  }

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(themeModeKey);

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


//主题色的本地存储类
class ColorStorage {
  static const String colorKey = 'theme_color';

  static Future<void> saveColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(colorKey, color.toARGB32());
  }

  static Future<Color> loadColor() async {  
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(colorKey);

    if (value == null) {
      return Colors.blue;
    } 
    return Color(value);  
  }
}