import 'package:flutter/material.dart';
import '../data/local/hive_service.dart';

class AppProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _showSelfTransfersKey = 'show_self_transfers';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _showSelfTransfers = false;
  bool get showSelfTransfers => _showSelfTransfers;

  AppProvider() {
    _loadThemeMode();
    _loadShowSelfTransfers();
  }

  void _loadThemeMode() {
    final value = HiveService().settingsBox.get(_themeModeKey);
    switch (value) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
  }

  void _loadShowSelfTransfers() {
    final value = HiveService().settingsBox.get(_showSelfTransfersKey);
    if (value == true || value == 'true') {
      _showSelfTransfers = true;
    } else {
      _showSelfTransfers = false;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await HiveService().settingsBox.put(_themeModeKey, value);
    notifyListeners();
  }

  Future<void> setShowSelfTransfers(bool show) async {
    _showSelfTransfers = show;
    await HiveService().settingsBox.put(_showSelfTransfersKey, show.toString());
    notifyListeners();
  }
}
