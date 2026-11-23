import 'package:bookease/core/storage/local_storage_service.dart';

/// App-level user settings (currently theme mode).
class SettingsRepository {
  static const String _keyDarkMode = 'bookease_dark_mode';

  final LocalStorageService _storage;
  SettingsRepository(this._storage);

  bool getDarkMode() => _storage.getBool(_keyDarkMode) ?? false;

  Future<void> saveDarkMode(bool isDark) async {
    await _storage.setBool(_keyDarkMode, isDark);
  }
}
