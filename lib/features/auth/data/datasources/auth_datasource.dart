import 'package:bookease/features/auth/data/models/user_model.dart';

class AuthResult {
  final UserModel user;
  final String token;
  const AuthResult(this.user, this.token);
}

class SignupRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final UserRole role;
  final String? businessName;
  final String? businessCategory;

  const SignupRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.businessName,
    this.businessCategory,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.apiValue,
        if (businessName != null) 'businessName': businessName,
        if (businessCategory != null) 'businessCategory': businessCategory,
      };
}

/// Where accounts live. Implemented by a local (mock) store today and a
/// REST source for the Node.js backend.
abstract class AuthDataSource {
  Future<AuthResult> signup(SignupRequest request);
  Future<AuthResult> login(String email, String password);
  Future<UserModel> getCurrentUser(String token);
  Future<UserModel> updateProfile(UserModel user, String token);
  Future<void> changePassword(String currentPassword, String newPassword, String token);
}
