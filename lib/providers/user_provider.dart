import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final StorageService _storageService;

  UserModel _user = const UserModel(
    name: 'Areeba Khushi',
    email: 'areebakhushi3@gmail.com',
    phone: '+92 300 1234567',
    joinedDate: 'November 2026',
    notificationsEnabled: true,
    darkMode: false,
    hasCompletedOnboarding: false,
  );

  UserProvider(this._storageService) {
    _loadUser();
  }

  UserModel get user => _user;
  bool get hasCompletedOnboarding => _user.hasCompletedOnboarding;

  void _loadUser() {
    final saved = _storageService.getProfile();
    final onboardingDone = _storageService.getHasCompletedOnboarding();
    if (saved != null) {
      _user = saved.copyWith(hasCompletedOnboarding: onboardingDone);
    } else {
      _user = _user.copyWith(hasCompletedOnboarding: onboardingDone);
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    _user = _user.copyWith(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
    );
    notifyListeners();
    await _storageService.saveProfile(_user);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _user = _user.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await _storageService.saveProfile(_user);
  }

  Future<void> completeOnboarding() async {
    _user = _user.copyWith(hasCompletedOnboarding: true);
    notifyListeners();
    await _storageService.saveHasCompletedOnboarding(true);
  }

  Future<void> clearAllData() async {
    await _storageService.clearAll();
    _user = const UserModel(
      name: 'Areeba Khushi',
      email: 'areebakhushi3@gmail.com',
      phone: '+92 300 1234567',
      joinedDate: 'November 2026',
      notificationsEnabled: true,
      darkMode: false,
      hasCompletedOnboarding: false,
    );
    notifyListeners();
  }
}
