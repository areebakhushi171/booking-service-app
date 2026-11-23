import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_categories.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/custom_button.dart';
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
    final completed = bookings.completedBookings;
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
              // Top Greeting Row with Notifications
              Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: theme.colorScheme.primary.withAlpha(30),
                    child: Text(
                      user.initials,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                  IconButton(
                    icon: Badge(
                      isLabelVisible: notificationProvider.unreadCount > 0,
                      label: Text('${notificationProvider.unreadCount}'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s16),

              // Earnings Banner Header card
              Container(
                padding: EdgeInsets.all(AppSizes.s20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
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
                      SizedBox(height: 4.h),
                      Text(
                        category,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                    SizedBox(height: AppSizes.s16),
                    Text(
                      'Total earnings',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      'Rs ${bookings.providerEarnings.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.s16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.design_services_rounded,
                      value: '${services.services.length}',
                      label: 'My services',
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.pending_actions_rounded,
                      value: '${upcoming.length}',
                      label: 'Upcoming',
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.check_circle_rounded,
                      value: '${completed.length}',
                      label: 'Completed',
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.visibility_rounded,
                      value: '${services.activeCount}',
                      label: 'Live listings',
                      color: AppColors.accentTeal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s20),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Add service',
                      icon: Icons.add_rounded,
                      onPressed: () => onOpenTab(1),
                    ),
                  ),
                  SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: CustomButton(
                      label: 'Requests',
                      icon: Icons.inbox_rounded,
                      isOutlined: true,
                      onPressed: () => onOpenTab(2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s24),

              // Next requests
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Upcoming bookings',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (upcoming.length > 3)
                    TextButton(
                      onPressed: () => onOpenTab(2),
                      child: const Text('See all'),
                    ),
                ],
              ),
              SizedBox(height: AppSizes.s8),
              if (upcoming.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSizes.s20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    border: Border.all(
                        color: theme.colorScheme.onSurface.withAlpha(20)),
                  ),
                  child: Text(
                    services.services.isEmpty
                        ? 'Add your first service so customers can start booking you.'
                        : 'No upcoming bookings yet. They will appear here as soon as a customer books one of your services.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                )
              else
                ...upcoming
                    .take(3)
                    .map((b) => BookingRequestCard(booking: b)),
            ],
          ),
        ),
      ),
    );
  }
}
