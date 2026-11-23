import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_constants.dart';
import 'package:bookease/core/constants/app_routes.dart';
import 'package:bookease/core/theme/app_theme.dart';
import 'package:bookease/core/utils/responsive_utils.dart';
import 'package:bookease/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:bookease/features/customer/presentation/screens/main_navigation_screen.dart';
import 'package:bookease/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bookease/features/profile/providers/theme_provider.dart';
import 'package:bookease/features/provider/presentation/screens/provider_shell_screen.dart';
import 'package:bookease/features/splash/presentation/screens/splash_screen.dart';

class BookEaseApp extends StatelessWidget {
  const BookEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ScreenUtilInit(
      designSize: ResponsiveUtils.designSize(),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),
          AppRoutes.customerHome: (_) => const MainNavigationScreen(),
          AppRoutes.providerHome: (_) => const ProviderShellScreen(),
        },
      ),
    );
  }
}
