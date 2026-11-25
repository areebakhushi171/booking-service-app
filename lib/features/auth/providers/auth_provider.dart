import 'package:flutter/foundation.dart';

import 'package:bookease/core/errors/app_exceptions.dart';
import 'package:bookease/core/services/socket_service.dart';
import 'package:bookease/features/auth/data/datasources/auth_datasource.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';
import 'package:bookease/features/auth/data/repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final SocketService? _socketService;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _onboardingDone = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository, [this._socketService]);

  static const UserModel _guest = UserModel(
    id: '',
    name: 'Guest',
    email: '',
    phone: '',
  );

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get hasCompletedOnboarding => _onboardingDone;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _user;

  /// Non-null convenience for screens that are only shown after login.
  UserModel get user => _user ?? _guest;

  /// Called from the splash screen: loads onboarding flag and restores the session.
  Future<void> init() async {
    _onboardingDone = await _repository.hasCompletedOnboarding();
    _user = await _repository.restoreSession();
    _status =
        _user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    if (_status == AuthStatus.authenticated) {
      _socketService?.connect(userId: _user!.id);
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    notifyListeners();
    await _repository.setOnboardingCompleted(true);
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) {
    return _run(() async {
      final user = await _repository.login(email, password);
      if (user.role != expectedRole) {
        await _repository.logout();
        throw AuthException(
          'This account is registered as a ${user.role.label}. '
          'Please choose the ${user.role.label} option to continue.',
        );
      }
      return user;
    });
  }

  Future<bool> signup(SignupRequest request) {
    return _run(() => _repository.signup(request));
  }

  Future<bool> _run(Future<UserModel> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await action();
      _status = AuthStatus.authenticated;
      _socketService?.connect(userId: _user!.id);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.changePassword(currentPassword, newPassword);
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage =
          'Failed to change password. Please check your current password.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _socketService?.disconnect();
    await _repository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final current = _user;
    if (current == null) return;
    final updated = await _repository.updateProfile(current.copyWith(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
    ));
    _user = updated;
    notifyListeners();
  }

  Future<bool> uploadAvatar(dynamic imageFile) async {
    final current = _user;
    if (current == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final path = imageFile is String ? imageFile : imageFile.path;
      final updated = await _repository.uploadAvatar(path, current);
      _user = updated;
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to upload profile picture. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeAvatar() async {
    final current = _user;
    if (current == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.removeAvatar(current);
      _user = updated;
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to remove profile picture.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final current = _user;
    if (current == null) return;
    _user = current.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await _repository.cacheUser(_user!);
  }
}
