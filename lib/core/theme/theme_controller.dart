import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _storageKey = "app_theme_mode";

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  ThemeController() {
    _loadTheme();
  }

  // --------------------------------------------------
  // LOAD SAVED THEME
  // --------------------------------------------------
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_storageKey);

    if (value == "dark") {
      _themeMode = ThemeMode.dark;
    } else if (value == "system") {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  // --------------------------------------------------
  // SET THEME
  // --------------------------------------------------
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_storageKey, "dark");
    } else if (mode == ThemeMode.system) {
      await prefs.setString(_storageKey, "system");
    } else {
      await prefs.setString(_storageKey, "light");
    }

    notifyListeners();
  }

  // --------------------------------------------------
  // QUICK TOGGLES (FUTURE UI USE)
  // --------------------------------------------------
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setTheme(ThemeMode.dark);
    } else {
      setTheme(ThemeMode.light);
    }
  }
}
