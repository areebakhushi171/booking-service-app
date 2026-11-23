import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/theme/app_decorations.dart';
import 'package:bookease/features/auth/data/models/user_model.dart';

Color roleColor(UserRole role) =>
    role == UserRole.provider ? AppColors.accentTeal : AppColors.primary;

IconData roleIcon(UserRole role) => role == UserRole.provider
    ? Icons.storefront_rounded
    : Icons.event_available_rounded;

/// Icon, title and subtitle shown at the top of login / signup.
class AuthHeader extends StatelessWidget {
  final UserRole role;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.role,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = roleColor(role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: AppDecorations.tintedIconBox(color),
              child: Icon(roleIcon(role), size: 32.sp, color: color),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                role.label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          title,
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(160),
          ),
        ),
      ],
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(25),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
