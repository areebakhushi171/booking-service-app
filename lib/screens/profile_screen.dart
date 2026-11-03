import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: userProvider.user.name);
    final emailCtrl = TextEditingController(text: userProvider.user.email);
    final phoneCtrl = TextEditingController(text: userProvider.user.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone (PK)'),
                  validator: Validators.validatePhone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await userProvider.updateProfile(
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  phone: phoneCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BookEase',
      applicationVersion: '1.0.0+1',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _showEditProfileDialog(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),

            // About Card
            Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded,
                    color: theme.colorScheme.primary),
                title: const Text('About BookEase'),
                subtitle: const Text('Version 1.0.0 • Architecture & Credits'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showAboutDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
