import 'package:shared_preferences/shared_preferences.dart';

/// Thin, generic wrapper over SharedPreferences.
/// Feature data sources own their keys and (de)serialization.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async =>
      LocalStorageService(await SharedPreferences.getInstance());

  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
}
