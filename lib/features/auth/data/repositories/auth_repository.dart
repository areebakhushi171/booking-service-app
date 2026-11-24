import 'package:bookease/features/auth/data/datasources/auth_datasource.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';

/// Contract for authentication and the current session.
abstract class AuthRepository {
  Future<UserModel> signup(SignupRequest request);
  Future<UserModel> login(String email, String password);
  Future<UserModel?> restoreSession();
  Future<UserModel> updateProfile(UserModel user);
  Future<UserModel> uploadAvatar(String filePath, UserModel currentUser);
  Future<UserModel> removeAvatar(UserModel currentUser);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> cacheUser(UserModel user);
  Future<void> logout();
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted(bool done);
}
