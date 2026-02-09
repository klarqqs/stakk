import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeData get lightTheme => AppTheme.light;
  ThemeData get darkTheme => AppTheme.dark;

  ThemeProvider() {
    _loadTheme();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(StorageKeys.themeMode);
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.themeMode, mode.name);
    notifyListeners();
  }
}
