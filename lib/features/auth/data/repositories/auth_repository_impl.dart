import 'dart:convert';

import 'package:bookease/core/errors/app_exceptions.dart';
import 'package:bookease/core/network/network_exceptions.dart';
import 'package:bookease/core/storage/local_storage_service.dart';
import 'package:bookease/core/storage/token_storage.dart';
import 'package:bookease/features/auth/data/datasources/auth_datasource.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';
import 'package:bookease/features/auth/data/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String _keyProfile = 'bookease_profile';
  static const String _keyOnboardingDone = 'bookease_onboarding_done';

  final AuthDataSource _source;
  final TokenStorage _tokens;
  final LocalStorageService _storage;

  AuthRepositoryImpl(this._source, this._tokens, this._storage);

  @override
  Future<UserModel> signup(SignupRequest request) async {
    final result = await _source.signup(request);
    await _tokens.saveToken(result.token);
    await cacheUser(result.user);
    return result.user;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final result = await _source.login(email, password);
    await _tokens.saveToken(result.token);
    await cacheUser(result.user);
    return result.user;
  }

  @override
  Future<UserModel?> restoreSession() async {
    final token = _tokens.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _source.getCurrentUser(token);
      await cacheUser(user);
      return user;
    } on UnauthorizedException {
      await _clearSession();
      return null;
    } on AuthException {
      await _clearSession();
      return null;
    } on NetworkException {
      return _readCachedUser();
    }
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final token = _tokens.readToken() ?? '';
    final updated = await _source.updateProfile(user, token);
    await cacheUser(updated);
    return updated;
  }

  @override
  Future<UserModel> uploadAvatar(String filePath, UserModel currentUser) async {
    final token = _tokens.readToken() ?? '';
    final updated = await _source.uploadAvatar(filePath, token, currentUser: currentUser);
    await cacheUser(updated);
    return updated;
  }

  @override
  Future<UserModel> removeAvatar(UserModel currentUser) async {
    final token = _tokens.readToken() ?? '';
    final updated = await _source.removeAvatar(token, currentUser);
    await cacheUser(updated);
    return updated;
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = _tokens.readToken() ?? '';
    await _source.changePassword(currentPassword, newPassword, token);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await _storage.setString(_keyProfile, jsonEncode(user.toJson()));
  }

  @override
  Future<void> logout() => _clearSession();

  Future<void> _clearSession() async {
    await _tokens.clear();
    await _storage.remove(_keyProfile);
  }

  UserModel? _readCachedUser() {
    try {
      final raw = _storage.getString(_keyProfile);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> hasCompletedOnboarding() async =>
      _storage.getBool(_keyOnboardingDone) ?? false;

  @override
  Future<void> setOnboardingCompleted(bool done) async {
    await _storage.setBool(_keyOnboardingDone, done);
  }
}
