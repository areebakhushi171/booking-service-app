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

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _float;
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

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onComplete() {
    context.read<AuthProvider>().completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
  }

  Widget _illustration(Color color, IconData icon) {
    final base = 230.r;
    return AnimatedBuilder(
      animation: _float,
      builder: (_, __) {
        final dy = (_float.value - 0.5) * 14;
        return SizedBox(
          width: base,
          height: base,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: base,
                height: base,
                decoration: BoxDecoration(
                  color: color.withAlpha(16),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: base * 0.76,
                height: base * 0.76,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                ),
              ),
              Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: base * 0.52,
                  height: base * 0.52,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(90),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 56.sp, color: Colors.white),
                ),
              ),
              Positioned(
                top: base * 0.08,
                right: base * 0.12,
                child: Transform.translate(
                  offset: Offset(0, -dy),
                  child: Container(
                    width: 18.r,
                    height: 18.r,
                    decoration: BoxDecoration(
                      color: color.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: base * 0.1,
                left: base * 0.1,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    width: 12.r,
                    height: 12.r,
                    decoration: BoxDecoration(
                      color: color.withAlpha(90),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 8.h, 16.w, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: isLast ? null : _onComplete,
                    style: TextButton.styleFrom(
                      backgroundColor:
                      theme.colorScheme.onSurface.withAlpha(14),
                      shape: const StadiumBorder(),
                      padding:
                      EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(170),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        _illustration(
                            slide['color'] as Color, slide['icon'] as IconData),
                        SizedBox(height: 36.h),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(32.r, 8.r, 32.r, 28.r),
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
                        width: _currentPage == idx ? 28.w : 8.w,
                        decoration: BoxDecoration(
                          color: _currentPage == idx
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(40),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: isLast ? 'Get Started' : 'Next',
                      icon: Icons.arrow_forward_rounded,
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