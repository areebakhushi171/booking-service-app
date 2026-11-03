import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/booking_provider.dart';
import 'providers/service_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  final storageService = StorageService(sharedPreferences);

  final notificationService = NotificationService();
  await notificationService.init();

  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(apiService, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(storageService, notificationService),
        ),
      ],
      child: const BookEaseApp(),
    ),
  );
}

class BookEaseApp extends StatelessWidget {
  const BookEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    return MaterialApp(
      title: 'BookEase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: _determineInitialScreen(userProvider),
    );
  }

  Widget _determineInitialScreen(UserProvider userProvider) {
    if (!userProvider.hasCompletedOnboarding) {
      return const OnboardingScreen();
    }
    return const MainNavigationScreen();
  }
}
