/// User profile model for BookEase customer
class UserModel {
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String joinedDate;
  final bool notificationsEnabled;
  final bool darkMode;
  final bool hasCompletedOnboarding;

  const UserModel({
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.joinedDate,
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.hasCompletedOnboarding = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String? ?? 'Areeba Khushi',
      email: json['email'] as String? ?? 'areebakhushi3@gmail.com',
      phone: json['phone'] as String? ?? '+92 300 1234567',
      avatarUrl: json['avatarUrl'] as String?,
      joinedDate: json['joinedDate'] as String? ?? 'November 2026',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'joinedDate': joinedDate,
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? joinedDate,
    bool? notificationsEnabled,
    bool? darkMode,
    bool? hasCompletedOnboarding,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return 'BE';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
