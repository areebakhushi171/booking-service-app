import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/header_circle_button.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/core/widgets/user_avatar.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bookease/features/notifications/providers/notification_provider.dart';
import 'package:bookease/features/provider/presentation/widgets/booking_request_card.dart';
import 'package:bookease/features/provider/presentation/widgets/stat_card.dart';
import 'package:bookease/features/provider/providers/provider_services_provider.dart';

/// Provider home: earnings, counters, quick actions and the next requests.
class ProviderDashboardScreen extends StatelessWidget {
  /// Switches the shell to another tab (1 = My Services, 2 = Requests).
  final ValueChanged<int> onOpenTab;

  const ProviderDashboardScreen({super.key, required this.onOpenTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;
    final services = context.watch<ProviderServicesProvider>();
    final bookings = context.watch<BookingProvider>();
    final notificationProvider = context.watch<NotificationProvider>();

    final upcoming = bookings.upcomingBookings;
    final dashboard = bookings.dashboardSummary;
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    final category = user.businessCategory == null
        ? null
        : AppCategories.nameOf(user.businessCategory!);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: AppSizes.screenPadding,
            children: [
              // Header
              Row(
                children: [
                  UserAvatar(
                    avatarUrl: user.avatarUrl,
                    name: user.name,
                    radius: 22.r,
                  ),
                  SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${user.name.split(' ').first}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.businessName ?? category ?? 'Service Provider',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                  HeaderCircleButton(
                    icon: Icons.notifications_outlined,
                    tooltip: 'Notifications',
                    badgeCount: notificationProvider.unreadCount,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s16),

              // Earnings banner
              FadeSlideIn(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  child: Container(
                    padding: EdgeInsets.all(AppSizes.s20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -36.r,
                          top: -46.r,
                          child: _Circle(size: 140.r, alpha: 26),
                        ),
                        Positioned(
                          right: 50.r,
                          bottom: -56.r,
                          child: _Circle(size: 110.r, alpha: 18),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Business Performance',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                user.businessName ?? user.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (category != null) ...[
                                SizedBox(height: 6.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: AppSizes.s16),
                              Text(
                                'Total earnings',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                              Text(
                                dashboard == null
                                    ? '—'
                                    : 'Rs ${dashboard.totalEarnings.toStringAsFixed(0)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.s16),

              // Stats 2x2
              Row(
                children: [
                  Expanded(
                    child: FadeSlideIn(
                      index: 1,
                      child: StatCard(
                        icon: Icons.design_services_rounded,
                        value: '${services.services.length}',
                        label: 'My services',
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: FadeSlideIn(
                      index: 2,
                      child: StatCard(
                        icon: Icons.pending_actions_rounded,
                        value: dashboard == null
                            ? '—'
                            : '${dashboard.pendingBookingsCount}',
                        label: 'Upcoming',
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  Expanded(
                    child: FadeSlideIn(
                      index: 3,
                      child: StatCard(
                        icon: Icons.check_circle_rounded,
                        value: dashboard == null
                            ? '—'
                            : '${dashboard.completedBookingsCount}',
                        label: 'Completed',
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: FadeSlideIn(
                      index: 4,
                      child: StatCard(
                        icon: Icons.visibility_rounded,
                        value: '${services.activeCount}',
                        label: 'Live listings',
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s20),

              // Upcoming
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Upcoming bookings',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (upcoming.length > 3)
                    TextButton(
                      onPressed: () => onOpenTab(2),
                      child: const Text('See all'),
                    ),
                ],
              ),
              SizedBox(height: AppSizes.s12),
              if (upcoming.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSizes.s20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                        color: theme.colorScheme.onSurface.withAlpha(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46.r,
                        height: 46.r,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.event_available_rounded,
                            color: theme.colorScheme.primary),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          services.services.isEmpty
                              ? 'Add your first service so customers can start booking you.'
                              : 'No upcoming bookings yet. They will appear here as soon as a customer books one of your services.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...upcoming.take(3).map((b) => BookingRequestCard(booking: b)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final int alpha;
  const _Circle({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(alpha),
        ),
      );
}
