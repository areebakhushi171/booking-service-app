import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/features/chat/presentation/screens/conversations_screen.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/notifications/data/models/notification_model.dart';
import 'package:bookease/features/notifications/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _onNotificationTap(BuildContext context, NotificationModel item) {
    context.read<NotificationProvider>().markAsRead(item.id);

    final bookingProvider = context.read<BookingProvider>();
    final type = (item.type ?? '').toLowerCase();

    // Check if notification refers to a booking
    if (type.contains('booking') || type.contains('appointment') || item.referenceId != null) {
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

    // Check if notification refers to chat/message
    if (type.contains('chat') || type.contains('message')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ConversationsScreen(),
        ),
      );
      return;
    }

    // Default: Show notification details dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(_getIcon(item.type), color: Theme.of(ctx).colorScheme.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.message, style: TextStyle(fontSize: 14.sp, height: 1.4)),
            SizedBox(height: 12.h),
            Text(
              _formatDate(item.createdAt),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: provider.isLoading && provider.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? EmptyStateView(
                  icon: Icons.notifications_off_outlined,
                  title: 'No Notifications Yet',
                  message: 'You are all caught up! Booking updates, alerts, and reminders will appear here.',
                  buttonText: 'Refresh',
                  onButtonPressed: () => provider.loadNotifications(),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadNotifications(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, idx) {
                      final item = provider.notifications[idx];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) => provider.deleteNotification(item.id),
                        child: Card(
                          elevation: item.isRead ? 0 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(
                              color: item.isRead
                                  ? theme.dividerColor.withAlpha(30)
                                  : theme.colorScheme.primary.withAlpha(60),
                            ),
                          ),
                          color: item.isRead
                              ? theme.cardColor
                              : theme.colorScheme.primary.withAlpha(12),
                          margin: EdgeInsets.only(bottom: 12.h),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.r),
                            onTap: () => _onNotificationTap(context, item),
                            child: Padding(
                              padding: EdgeInsets.all(14.r),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20.r,
                                    backgroundColor: item.isRead
                                        ? Colors.grey.shade200
                                        : theme.colorScheme.primary.withAlpha(40),
                                    child: Icon(
                                      _getIcon(item.type),
                                      size: 20.sp,
                                      color: item.isRead
                                          ? Colors.grey.shade700
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                  fontSize: 14.sp,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              _formatDate(item.createdAt),
                                              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          item.message,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: theme.colorScheme.onSurface.withAlpha(180),
                                            height: 1.3,
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
                      );
                    },
                  ),
                ),
    );
  }

  static IconData _getIcon(String? type) {
    if (type == null) return Icons.notifications_rounded;
    final t = type.toLowerCase();
    if (t.contains('booking') || t.contains('appointment')) return Icons.calendar_month_rounded;
    if (t.contains('message') || t.contains('chat')) return Icons.chat_bubble_rounded;
    if (t.contains('offer') || t.contains('promo')) return Icons.local_offer_rounded;
    return Icons.notifications_rounded;
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }
}
