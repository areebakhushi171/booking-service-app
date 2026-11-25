import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/provider/data/service_image_presets.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.watch<BookingProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(56.h),
            child: Container(
              height: 44.h,
              margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(14),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                splashBorderRadius: BorderRadius.circular(20.r),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withAlpha(175),
                labelStyle:
                    TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                tabs: [
                  _BookingCountTab(
                      label: 'Pending', count: p.upcomingBookings.length),
                  _BookingCountTab(
                      label: 'Accepted', count: p.acceptedBookings.length),
                  _BookingCountTab(
                      label: 'Done', count: p.completedBookings.length),
                  _BookingCountTab(
                      label: 'Cancelled', count: p.cancelledBookings.length),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsTab(status: BookingStatus.upcoming),
            _BookingsTab(status: BookingStatus.confirmed),
            _BookingsTab(status: BookingStatus.completed),
            _BookingsTab(status: BookingStatus.cancelled),
          ],
        ),
      ),
    );
  }
}

class _BookingCountTab extends StatelessWidget {
  final String label;
  final int count;
  const _BookingCountTab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            SizedBox(width: 6.w),
            Container(
              width: 22.r,
              height: 22.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Text('$count',
                  style:
                      TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsTab extends StatelessWidget {
  final BookingStatus status;

  const _BookingsTab({required this.status});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    List<BookingModel> list;
    String emptyTitle;
    String emptyMessage;

    switch (status) {
      case BookingStatus.upcoming:
        list = bookingProvider.upcomingBookings;
        emptyTitle = 'No Pending Appointments';
        emptyMessage =
            'You have no pending bookings at the moment. Explore services to make your first appointment!';
        break;
      case BookingStatus.confirmed:
        list = bookingProvider.acceptedBookings;
        emptyTitle = 'No Accepted Appointments';
        emptyMessage = 'Bookings accepted by providers will appear here.';
        break;
      case BookingStatus.completed:
        list = bookingProvider.completedBookings;
        emptyTitle = 'No Completed Services';
        emptyMessage = 'Past completed service records will appear here.';
        break;
      case BookingStatus.cancelled:
        list = bookingProvider.cancelledBookings;
        emptyTitle = 'No Cancelled Bookings';
        emptyMessage = 'Cancelled and rejected bookings will appear here.';
        break;
      case BookingStatus.rejected:
        list = bookingProvider.cancelledBookings
            .where((booking) => booking.status == BookingStatus.rejected)
            .toList();
        emptyTitle = 'No Rejected Bookings';
        emptyMessage = 'Rejected booking requests will appear here.';
        break;
    }

    if (list.isEmpty) {
      return EmptyStateView(
        icon: Icons.event_note_rounded,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          itemCount: list.length,
          itemBuilder: (context, idx) => FadeSlideIn(
            index: idx,
            child: _BookingCard(booking: list[idx]),
          ),
        ),
      ),
    );
  }
}

(Color, String) _statusMeta(BuildContext context, BookingStatus s) {
  final theme = Theme.of(context);
  switch (s) {
    case BookingStatus.upcoming:
      return (AppColors.warning, 'Pending');
    case BookingStatus.confirmed:
      return (theme.colorScheme.secondary, 'Accepted');
    case BookingStatus.completed:
      return (AppColors.success, 'Completed');
    case BookingStatus.cancelled:
      return (AppColors.error, 'Cancelled');
    case BookingStatus.rejected:
      return (AppColors.error, 'Rejected');
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  Future<void> _showCancelDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        icon: CircleAvatar(
          radius: 28.r,
          backgroundColor: AppColors.error.withAlpha(30),
          child: Icon(Icons.event_busy_rounded,
              color: AppColors.error, size: 28.sp),
        ),
        title: const Text('Cancel Appointment?', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your appointment for ${booking.serviceName}?',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 14.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation (optional)',
                hintText: 'e.g. Schedule conflict, unexpected travel',
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BookingProvider>().cancelBooking(
                    booking.id,
                    reason: reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : null,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Appointment has been cancelled.')),
                );
              }
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
    reasonController.dispose();
  }

  Widget _placeholderImage(double s) => Container(
        width: s,
        height: s,
        color: Colors.grey.withAlpha(50),
        child: Icon(Icons.image_not_supported_outlined,
            size: 24.sp, color: Colors.grey),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isAccepted = booking.status == BookingStatus.confirmed;
    final (statusColor, statusLabel) = _statusMeta(context, booking.status);
    final img = 78.r;
    final bookingImageUrl = booking.serviceImageUrl.trim().isNotEmpty
        ? booking.serviceImageUrl.trim()
        : ServiceImagePresets.forCategory(booking.serviceCategory);
    final muted = theme.colorScheme.onSurface.withAlpha(150);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BookingDetailScreen(booking: booking)),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: CachedNetworkImage(
                      imageUrl: bookingImageUrl,
                      width: img,
                      height: img,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: img,
                        height: img,
                        color: Colors.grey.withAlpha(40),
                      ),
                      errorWidget: (_, __, ___) => _placeholderImage(img),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${booking.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            StatusPill(label: statusLabel, color: statusColor),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          booking.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${booking.formattedServicePrice} • ${booking.durationMinutes} min',
                          style: TextStyle(color: muted, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.calendar_today_rounded,
                      text: booking.bookingDate,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.schedule_rounded,
                      text: '${booking.startTime} - ${booking.endTime}',
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              if (booking.customerNotes != null &&
                  booking.customerNotes!.trim().isNotEmpty) ...[
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_rounded, size: 15.sp, color: muted),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          booking.customerNotes!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isUpcoming || isAccepted) ...[
                Divider(height: 28.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withAlpha(100)),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                    ),
                    if (isAccepted) ...[
                      SizedBox(width: 8.w),
                      FilledButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Mark booking as done?'),
                              content: const Text(
                                  'Confirm that this service has been completed.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Not yet'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !context.mounted) return;
                          try {
                            await context
                                .read<BookingProvider>()
                                .completeBooking(booking.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Booking marked as completed!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Failed to complete booking: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Done'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniInfo(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}
