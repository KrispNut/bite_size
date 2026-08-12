import 'package:flutter/material.dart';
import '/core/constants/app_constants.dart';

class ThemeService extends ChangeNotifier {
  // Singleton pattern
  static final ThemeService instance = ThemeService._internal();

  factory ThemeService() {
    return instance;
  }

  ThemeService._internal();

  // Initialize with the constant. If null, default to system,
  // but Splash will overwrite this immediately anyway.
  ThemeMode themeMode = AppConstants.currentTheme ?? ThemeMode.light;

  bool get isDarkMode {
    return themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    // STRICT TOGGLE: Only swap between Light and Dark.
    // Never set to .system here.
    if (themeMode == ThemeMode.dark) {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.dark;
    }

    // Keep the constant in sync so other logic works
    AppConstants.currentTheme = themeMode;

    // This triggers the INSTANT UI update in main.dart
    notifyListeners();
  }

  // Called by Splash Screen to set the initial state
  void setTheme(ThemeMode mode) {
    themeMode = mode;
    AppConstants.currentTheme = mode;
    notifyListeners();
  }
}
