import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/core/constants/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Discover Verified Services',
      'subtitle':
          'From salon haircuts & soothing spa massages to AC master repair, certified tutors, nurses, and car detailing.',
      'icon': Icons.verified_rounded,
      'color': Color(0xFF1E5EFF),
    },
    {
      'title': 'Smart Scheduling, Zero Overlaps',
      'subtitle':
          'Choose your desired date and 100% available time slot. Our smart engine eliminates double booking conflicts instantly.',
      'icon': Icons.calendar_month_rounded,
      'color': Color(0xFF0D9488),
    },
    {
      'title': 'Instant Confirmation & Reminders',
      'subtitle':
          'Track upcoming appointments, reschedule with one tap, add events to your calendar, and get timely reminder notifications.',
      'icon': Icons.notifications_active_rounded,
      'color': Color(0xFF6366F1),
    },
  ];

  void _onComplete() {
    context.read<AuthProvider>().completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onComplete,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, idx) {
                  final slide = _slides[idx];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140.w,
                          height: 140.h,
                          decoration: BoxDecoration(
                            color: (slide['color'] as Color).withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 64.sp,
                            color: slide['color'] as Color,
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(32.r),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (idx) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        height: 8.h,
                        width: _currentPage == idx ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(40),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: _currentPage == _slides.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _onComplete();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
