import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  double _glassTransparency = 0.5;
  double get glassTransparency => _glassTransparency;
  late SharedPreferences _prefs;
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode {
    if (_isDarkMode) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.light;
    }
  }

  /// Initialize SharedPreferences and load saved theme preference
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    _glassTransparency = (_prefs.getDouble('glassTransparency') ?? 0.5).clamp(
      0.0,
      1.0,
    );
    notifyListeners();
  }

  Future<void> setGlassTransparency(double value) async {
    _glassTransparency = value.clamp(0.0, 1.0);
    notifyListeners();
    await _prefs.setDouble('glassTransparency', _glassTransparency);
  }

  /// Toggle theme and save to SharedPreferences
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  /// Set dark mode explicitly and save to SharedPreferences
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
}
