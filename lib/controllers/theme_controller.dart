import 'package:flutter/material.dart';
import 'package:system_theme/system_theme.dart';

import '../services/preferences_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blueAccent;
  bool _followSystemColor = true;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get followSystemColor => _followSystemColor;

  Color get systemAccentColor => SystemTheme.accentColor.accent;

  List<Color> get presetColors => [
    systemAccentColor,
    Colors.purple,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.yellowAccent,
    Colors.green,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.brown,
  ];

  Future<void> init() async {
    try {
      await SystemTheme.accentColor.load();
      _accentColor = systemAccentColor;
    } catch (_) {}

    try {
      final saved = await PreferencesService.instance.loadThemePreferences();
      _themeMode = saved.themeMode;
      _followSystemColor = saved.followSystemColor;
      if (_followSystemColor) {
        _accentColor = systemAccentColor;
      } else if (saved.customColor != null) {
        _accentColor = saved.customColor!;
      }
      notifyListeners();
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void selectColorOption(Color color, {required bool isSystemOption}) {
    _followSystemColor = isSystemOption;
    _accentColor = isSystemOption ? systemAccentColor : color;
    notifyListeners();
  }

  void restoreSnapshot({
    required ThemeMode mode,
    required Color color,
    required bool followSystem,
  }) {
    _themeMode = mode;
    _accentColor = color;
    _followSystemColor = followSystem;
    notifyListeners();
  }

  Future<void> persist() async {
    await PreferencesService.instance.saveThemePreferences(
      themeMode: _themeMode,
      followSystemColor: _followSystemColor,
      accentColor: _accentColor,
    );
  }
}
