import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/header_circle_button.dart';
import 'package:bookease/core/widgets/shimmer_loading.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/chat/presentation/screens/conversations_screen.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/notifications/data/models/notification_model.dart';
import 'package:bookease/features/notifications/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<bool?> _confirmDelete(BuildContext context, {bool isBulk = false}) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        title: Text(isBulk ? 'Delete All Notifications?' : 'Delete Notification?'),
        content: Text(
          isBulk
              ? 'Are you sure you want to delete all notifications? This action cannot be undone.'
              : 'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(BuildContext context, NotificationModel item) {
    context.read<NotificationProvider>().markAsRead(item.id);

    final bookingProvider = context.read<BookingProvider>();
    final type = (item.type ?? '').toLowerCase();

    if (type.contains('booking') ||
        type.contains('appointment') ||
        item.referenceId != null) {
      final refId = item.referenceId ?? item.id;
      final matching = bookingProvider.upcomingBookings
          .followedBy(bookingProvider.acceptedBookings)
          .followedBy(bookingProvider.completedBookings)
          .followedBy(bookingProvider.cancelledBookings)
          .where((b) => b.id == refId || b.id == item.referenceId)
          .toList();

      if (matching.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: matching.first),
          ),
        );
        return;
      }
    }

    if (type.contains('chat') || type.contains('message')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConversationsScreen()),
      );
      return;
    }

    final (icon, color) = _meta(context, item.type);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        icon: CircleAvatar(
          radius: 28.r,
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color, size: 26.sp),
        ),
        title: Text(
          item.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, height: 1.4)),
            SizedBox(height: 12.h),
            Text(
              _relativeTime(item.createdAt),
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(ctx).colorScheme.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = [...provider.notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    Widget body;
    if (provider.isLoading && items.isEmpty) {
      body = ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: 7,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ShimmerPlaceholder(width: double.infinity, height: 84.h),
        ),
      );
    } else if (provider.errorMessage != null && items.isEmpty) {
      body = EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: provider.errorMessage!,
        buttonText: 'Try Again',
        onButtonPressed: () => provider.loadNotifications(),
      );
    } else if (items.isEmpty) {
      body = EmptyStateView(
        icon: Icons.notifications_off_outlined,
        title: 'No Notifications Yet',
        message:
        'You are all caught up! Booking updates, alerts, and reminders will appear here.',
        buttonText: 'Refresh',
        onButtonPressed: () => provider.loadNotifications(),
      );
    } else {
      // Group: Today / Yesterday / Earlier
      final rows = <Object>[];
      int? lastGroup;
      for (final n in items) {
        final g = _group(n.createdAt);
        if (g != lastGroup) {
          rows.add(const ['Today', 'Yesterday', 'Earlier'][g]);
          lastGroup = g;
        }
        rows.add(n);
      }

      body = RefreshIndicator(
        onRefresh: () => provider.loadNotifications(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: rows.length,
          itemBuilder: (context, idx) {
            final row = rows[idx];
            if (row is String) {
              return Padding(
                padding: EdgeInsets.fromLTRB(4.w, 12.h, 4.w, 10.h),
                child: Text(
                  row,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(150),
                  ),
                ),
              );
            }
            final item = row as NotificationModel;
            return FadeSlideIn(
              index: idx,
              child: Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _confirmDelete(context),
                background: Container(
                  alignment: Alignment.centerRight,
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.only(right: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(30),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: CircleAvatar(
                    radius: 20.r,
                    backgroundColor: AppColors.error,
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 20.sp),
                  ),
                ),
                onDismissed: (_) => provider.deleteNotification(item.id),
                child: _NotificationCard(
                  item: item,
                  onTap: () => _onNotificationTap(context, item),
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context);
                    if (confirmed == true) {
                      provider.deleteNotification(item.id);
                    }
                  },
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (items.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: HeaderCircleButton(
                icon: Icons.delete_sweep_rounded,
                iconColor: AppColors.error,
                tooltip: 'Delete all notifications',
                onPressed: () async {
                  final confirmed = await _confirmDelete(context, isBulk: true);
                  if (confirmed == true && context.mounted) {
                    await provider.deleteAllNotifications();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All notifications deleted.')),
                      );
                    }
                  }
                },
              ),
            ),
          if (provider.unreadCount > 0)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: HeaderCircleButton(
                icon: Icons.done_all_rounded,
                tooltip: 'Mark all as read',
                onPressed: () => provider.markAllAsRead(),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      ),
    );
  }

  static int _group(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) return 0;
    if (diff == 1) return 1;
    return 2;
  }

  static (IconData, Color) _meta(BuildContext context, String? type) {
    final primary = Theme.of(context).colorScheme.primary;
    final t = (type ?? '').toLowerCase();
    if (t.contains('cancel') || t.contains('reject') || t.contains('alert')) {
      return (Icons.error_outline_rounded, AppColors.error);
    }
    if (t.contains('booking') || t.contains('appointment')) {
      return (Icons.calendar_month_rounded, AppColors.accentTeal);
    }
    if (t.contains('message') || t.contains('chat')) {
      return (Icons.chat_bubble_rounded, primary);
    }
    if (t.contains('offer') || t.contains('promo')) {
      return (Icons.local_offer_rounded, AppColors.warning);
    }
    return (Icons.notifications_rounded, primary);
  }

  static String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (_group(dt) == 0) return '${diff.inHours}h ago';
    if (_group(dt) == 1) return 'Yesterday';
    return '${dt.month}/${dt.day}';
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = NotificationsScreen._meta(context, item.type);
    final unread = !item.isRead;
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: unread ? primary.withAlpha(14) : theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: unread
                    ? primary.withAlpha(70)
                    : theme.colorScheme.onSurface.withAlpha(20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: color.withAlpha(unread ? 40 : 24),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 21.sp, color: color),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (unread) ...[
                            Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                          ],
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            NotificationsScreen._relativeTime(item.createdAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurface.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.3,
                          color: theme.colorScheme.onSurface
                              .withAlpha(unread ? 210 : 160),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                CircleActionButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete notification',
                  color: AppColors.error,
                  size: 34.r,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
