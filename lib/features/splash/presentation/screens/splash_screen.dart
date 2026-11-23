import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_routes.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_constants.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';

/// First screen: brand animation while the saved session is restored,
/// then routes to onboarding, role selection, or the correct panel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    // Run session restore and a minimum brand display time together.
    await Future.wait([
      auth.init(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);
    if (!mounted) return;

    if (!auth.hasCompletedOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    } else if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home(isProvider: auth.user.isProvider),
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accentTeal],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(22.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(36),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(color: Colors.white.withAlpha(70)),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 56.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        AppConstants.appName,
                        style: textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Book or offer services, effortlessly',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(210),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: 28.r,
                height: 28.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }
}
