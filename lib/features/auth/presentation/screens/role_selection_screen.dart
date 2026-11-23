import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';
import 'package:bookease/features/auth/presentation/screens/login_screen.dart';

/// Choose which panel to enter: Customer (book services) or Provider (offer services).
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selected = UserRole.customer;

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(role: _selected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSizes.authPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppSizes.maxFormWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How will you use BookEase?',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Pick your role. You can sign in or create an account for it next.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                  SizedBox(height: 28.h),
                  _RoleCard(
                    icon: Icons.event_available_rounded,
                    color: AppColors.primary,
                    title: 'I need a service',
                    subtitle:
                        'Browse verified providers, book a time slot and track your appointments.',
                    selected: _selected == UserRole.customer,
                    onTap: () => setState(() => _selected = UserRole.customer),
                  ),
                  SizedBox(height: 16.h),
                  _RoleCard(
                    icon: Icons.storefront_rounded,
                    color: AppColors.accentTeal,
                    title: 'I provide services',
                    subtitle:
                        'List your services, set your availability and manage incoming bookings.',
                    selected: _selected == UserRole.provider,
                    onTap: () => setState(() => _selected = UserRole.provider),
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: _selected == UserRole.customer
                          ? 'Continue as Customer'
                          : 'Continue as Provider',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _continue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(22) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: selected ? color : theme.dividerColor.withAlpha(60),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? color : theme.colorScheme.onSurface.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }
}
