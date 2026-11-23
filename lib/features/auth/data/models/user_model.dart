enum UserRole { customer, provider }

extension UserRoleX on UserRole {
  String get label => this == UserRole.customer ? 'Customer' : 'Service Provider';

  /// Value sent to / received from the API.
  String get apiValue => name; // 'customer' | 'provider'

  static UserRole parse(String? value) {
    return (value ?? '').toLowerCase() == 'provider'
        ? UserRole.provider
        : UserRole.customer;
  }
}

/// Signed-in account (customer or service provider).
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatarUrl;
  final String joinedDate;
  final String? businessName; // provider only
  final String? businessCategory; // provider only
  final bool notificationsEnabled;
  final bool darkMode;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = UserRole.customer,
    this.avatarUrl,
    this.joinedDate = '',
    this.businessName,
    this.businessCategory,
    this.notificationsEnabled = true,
    this.darkMode = false,
  });

  bool get isProvider => role == UserRole.provider;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRoleX.parse(json['role'] as String?),
      avatarUrl: json['avatarUrl'] as String?,
      joinedDate: json['joinedDate'] as String? ?? '',
      businessName: json['businessName'] as String?,
      businessCategory: json['businessCategory'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.apiValue,
      'avatarUrl': avatarUrl,
      'joinedDate': joinedDate,
      'businessName': businessName,
      'businessCategory': businessCategory,
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? joinedDate,
    String? businessName,
    String? businessCategory,
    bool? notificationsEnabled,
    bool? darkMode,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'BE';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
