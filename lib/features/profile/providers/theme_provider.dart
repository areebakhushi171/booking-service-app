import 'package:flutter/material.dart';
import 'package:bookease/features/profile/data/repositories/settings_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsRepository _repository;
  bool _isDarkMode = false;

  ThemeProvider(this._repository) {
    _isDarkMode = _repository.getDarkMode();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _repository.saveDarkMode(_isDarkMode);
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    await _repository.saveDarkMode(_isDarkMode);
  }
}
