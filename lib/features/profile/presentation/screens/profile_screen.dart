import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_routes.dart';
import 'package:bookease/core/widgets/user_avatar.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/chat/presentation/screens/conversations_screen.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bookease/features/notifications/providers/notification_provider.dart';
import 'package:bookease/features/profile/presentation/screens/change_password_screen.dart';
import 'package:bookease/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:bookease/features/profile/providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BookEase',
      applicationVersion: '1.0.0+1',
      applicationIcon: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
      ),
      children: const [
        Text(
          'BookEase is a portfolio-grade, production-quality Service Booking Mobile and Tablet App engineered in Flutter 3.x (Dart 3, Material 3).\n\nFeatures include smart scheduling without slot overlaps, resilient offline caching, live notifications, and adaptive navigation.',
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of BookEase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.roleSelection,
                  (route) => false,
                );
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            // User Header Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarUrl: user.avatarUrl,
                      name: user.name,
                      radius: 36.r,
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.phone,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 14.sp, color: theme.colorScheme.primary),
                                SizedBox(width: 4.w),
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Notifications & Chats Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
                    title: const Text('Notifications'),
                    subtitle: const Text('View system & booking updates'),
                    trailing: notificationProvider.unreadCount > 0
                        ? Badge(label: Text('${notificationProvider.unreadCount}'), child: const Icon(Icons.chevron_right_rounded))
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.chat_bubble_outline_rounded, color: theme.colorScheme.primary),
                    title: const Text('Messages & Chats'),
                    subtitle: const Text('Communicate with providers/customers'),
                    trailing: chatProvider.unreadCount > 0
                        ? Badge(label: Text('${chatProvider.unreadCount}'), child: const Icon(Icons.chevron_right_rounded))
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationsScreen())),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Preferences Card
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode Theme'),
                    subtitle: const Text('Toggle light / dark Material 3 styling'),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.setDarkMode(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Appointment Reminders'),
                    subtitle:
                        const Text('Receive local alerts 1 hour before bookings'),
                    secondary: Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                    value: user.notificationsEnabled,
                    onChanged: (val) =>
                        userProvider.setNotificationsEnabled(val),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Security & About
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline_rounded, color: theme.colorScheme.primary),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded,
                        color: theme.colorScheme.primary),
                    title: const Text('About BookEase'),
                    subtitle: const Text('Version 1.0.0 • Architecture & Credits'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Logout Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Sign out of your account'),
                onTap: () => _showLogoutDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
