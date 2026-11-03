import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyBookings = 'bookease_bookings';
  static const String _keyFavorites = 'bookease_favorites';
  static const String _keyProfile = 'bookease_profile';
  static const String _keyCachedServices = 'bookease_cached_services';
  static const String _keyDarkMode = 'bookease_dark_mode';
  static const String _keyOnboardingDone = 'bookease_onboarding_done';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Bookings ---
  List<BookingModel> getBookings() {
    try {
      final jsonString = _prefs.getString(_keyBookings);
      if (jsonString == null) return [];
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Corrupted storage fallback
      return [];
    }
  }

  Future<bool> saveBookings(List<BookingModel> bookings) async {
    final list = bookings.map((b) => b.toJson()).toList();
    return _prefs.setString(_keyBookings, jsonEncode(list));
  }

  // --- Favorites ---
  List<String> getFavorites() {
    try {
      return _prefs.getStringList(_keyFavorites) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveFavorites(List<String> favorites) async {
    return _prefs.setStringList(_keyFavorites, favorites);
  }

  // --- Profile ---
  UserModel? getProfile() {
    try {
      final jsonString = _prefs.getString(_keyProfile);
      if (jsonString == null) return null;
      final Map<String, dynamic> map =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveProfile(UserModel user) async {
    return _prefs.setString(_keyProfile, jsonEncode(user.toJson()));
  }

  // --- Cached Services (Offline support) ---
  List<ServiceModel> getCachedServices() {
    try {
      final jsonString = _prefs.getString(_keyCachedServices);
      if (jsonString == null) return [];
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> cacheServices(List<ServiceModel> services) async {
    final list = services.map((s) => s.toJson()).toList();
    return _prefs.setString(_keyCachedServices, jsonEncode(list));
  }

  // --- Dark Mode ---
  bool getDarkMode() {
    return _prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<bool> saveDarkMode(bool isDark) async {
    return _prefs.setBool(_keyDarkMode, isDark);
  }

  // --- Onboarding ---
  bool getHasCompletedOnboarding() {
    return _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<bool> saveHasCompletedOnboarding(bool done) async {
    return _prefs.setBool(_keyOnboardingDone, done);
  }

  // --- Clear Data ---
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
