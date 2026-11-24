import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';

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
                isScrollable: false,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                splashBorderRadius: BorderRadius.circular(20.r),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor:
                theme.colorScheme.onSurface.withAlpha(170),
                labelStyle:
                TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                tabs: [
                  Tab(text: 'Pending (${p.upcomingBookings.length})'),
                  Tab(text: 'Accepted (${p.acceptedBookings.length})'),
                  Tab(text: 'Done (${p.completedBookings.length})'),
                  Tab(text: 'Cancelled (${p.cancelledBookings.length})'),
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
        emptyMessage = 'You have not cancelled any bookings.';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
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
                  const SnackBar(content: Text('Appointment has been cancelled.')),
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

  void _showRescheduleModal(BuildContext context) {
    DateTime selectedDate =
        DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    String? selectedSlot = booking.startTime;
    final bookingProvider = context.read<BookingProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    final now = DateTime.now();
    final days = List.generate(
        30, (i) => DateTime(now.year, now.month, now.day + i));

    final service = serviceProvider.services.firstWhere(
          (s) => s.id == booking.serviceId,
      orElse: () => ServiceModel(
        id: booking.serviceId,
        name: booking.serviceName,
        category: booking.serviceCategory,
        description: '',
        price: booking.servicePrice,
        durationMinutes: booking.durationMinutes,
        imageUrl: booking.serviceImageUrl,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
            final slots = bookingProvider.getSlotStatuses(
              dateStr: dateStr,
              service: service,
              excludeBookingId: booking.id,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 12.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withAlpha(50),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reschedule Appointment',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        CircleActionButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Close',
                          color: theme.colorScheme.onSurface,
                          size: 38.r,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Pick a new date and conflict-free slot for ${booking.serviceName}.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      height: 78.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        itemBuilder: (_, i) {
                          final d = days[i];
                          final sel = d.year == selectedDate.year &&
                              d.month == selectedDate.month &&
                              d.day == selectedDate.day;
                          return GestureDetector(
                            onTap: () => setModalState(() {
                              selectedDate = d;
                              selectedSlot = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 58.w,
                              margin: EdgeInsets.only(right: 8.w),
                              decoration: BoxDecoration(
                                color: sel
                                    ? theme.colorScheme.primary
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: sel
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                      .withAlpha(25),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('EEE').format(d).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? theme.colorScheme.onPrimary
                                          .withAlpha(200)
                                          : theme.colorScheme.onSurface
                                          .withAlpha(140),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    DateFormat('dd').format(d),
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: sel
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      'Available Time Slots',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: slots.map((s) {
                        final isSelected = selectedSlot == s.time;
                        return ChoiceChip(
                          label: Text(s.time),
                          selected: isSelected,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          onSelected: s.isAvailable
                              ? (val) =>
                              setModalState(() => selectedSlot = s.time)
                              : null,
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Save New Schedule',
                        onPressed: selectedSlot != null
                            ? () async {
                          Navigator.pop(ctx);
                          await bookingProvider.rescheduleBooking(
                            bookingId: booking.id,
                            newDateStr: dateStr,
                            newStartTime: selectedSlot!,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Appointment rescheduled successfully!'),
                              ),
                            );
                          }
                        }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    final img = 64.r;
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
          MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
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
                    child: booking.serviceImageUrl.trim().isEmpty
                        ? _placeholderImage(img)
                        : CachedNetworkImage(
                      imageUrl: booking.serviceImageUrl,
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
                          'Rs ${booking.servicePrice.toStringAsFixed(0)} • ${booking.durationMinutes} min',
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
                    CircleActionButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Cancel booking',
                      label: 'Cancel',
                      color: AppColors.error,
                      onPressed: () => _showCancelDialog(context),
                    ),
                    if (isUpcoming) ...[
                      SizedBox(width: 18.w),
                      CircleActionButton(
                        icon: Icons.event_repeat_rounded,
                        tooltip: 'Reschedule booking',
                        label: 'Reschedule',
                        color: theme.colorScheme.secondary,
                        onPressed: () => _showRescheduleModal(context),
                      ),
                    ],
                    if (isAccepted) ...[
                      SizedBox(width: 18.w),
                      CircleActionButton(
                        icon: Icons.check_rounded,
                        tooltip: 'Mark as completed',
                        label: 'Complete',
                        color: AppColors.success,
                        onPressed: () async {
                          await context
                              .read<BookingProvider>()
                              .completeBooking(booking.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Booking marked as completed!'),
                              ),
                            );
                          }
                        },
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

  const _MiniInfo({required this.icon, required this.text, required this.color});

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