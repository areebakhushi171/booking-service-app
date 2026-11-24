import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/network/api_endpoints.dart';
import 'package:bookease/core/network/network_exceptions.dart';
import 'package:bookease/features/auth/data/datasources/auth_datasource.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';

/// REST implementation for the Node.js + Express + Prisma backend.
class AuthRemoteDataSource implements AuthDataSource {
  final ApiClient _client;
  AuthRemoteDataSource(this._client);

  AuthResult _parseAuth(Map<String, dynamic> body) {
    final token = body['token'] ?? body['accessToken'];
    final userJson = body['user'];
    if (token is! String || userJson is! Map<String, dynamic>) {
      throw const ParseException();
    }
    return AuthResult(UserModel.fromJson(userJson), token);
  }

  UserModel _parseUser(Map<String, dynamic> body) {
    final json = body['user'] is Map<String, dynamic>
        ? body['user'] as Map<String, dynamic>
        : body;
    return UserModel.fromJson(json);
  }

  @override
  Future<AuthResult> signup(SignupRequest request) async {
    final res = await _client.post(ApiEndpoints.signup, body: request.toJson());
    return _parseAuth(res.asMap);
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    final res = await _client.post(ApiEndpoints.login,
        body: {'email': email.trim(), 'password': password});
    return _parseAuth(res.asMap);
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    final res = await _client.get(ApiEndpoints.me);
    return _parseUser(res.asMap);
  }

  @override
  Future<UserModel> updateProfile(UserModel user, String token) async {
    final res = await _client.patch(ApiEndpoints.me, body: {
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      if (user.avatarUrl != null) 'avatarUrl': user.avatarUrl,
      if (user.businessName != null) 'businessName': user.businessName,
      if (user.businessCategory != null) 'businessCategory': user.businessCategory,
    });
    return _parseUser(res.asMap);
  }

  @override
  Future<UserModel> uploadAvatar(String filePath, String token, {UserModel? currentUser}) async {
    final res = await _client.uploadFile(
      ApiEndpoints.userAvatar,
      filePath: filePath,
      fieldName: 'avatar',
    );
    return _parseUser(res.asMap);
  }

  @override
  Future<UserModel> removeAvatar(String token, UserModel currentUser) async {
    final res = await _client.delete(ApiEndpoints.userAvatar);
    return _parseUser(res.asMap);
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String token) async {
    await _client.patch(ApiEndpoints.changePassword, body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': newPassword,
    });
  }
}
