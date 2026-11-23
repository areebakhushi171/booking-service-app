import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
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

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: list.length,
      itemBuilder: (context, idx) {
        final booking = list[idx];
        return _BookingCard(booking: booking);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your appointment for ${booking.serviceName}?',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
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
  }

  void _showRescheduleModal(BuildContext context) {
    DateTime selectedDate = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    String? selectedSlot = booking.startTime;
    final bookingProvider = context.read<BookingProvider>();
    final serviceProvider = context.read<ServiceProvider>();

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
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
                top: 20.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reschedule Appointment',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Pick a new date and conflict-free slot for ${booking.serviceName}.',
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                          selectedSlot = null;
                        });
                      }
                    },
                    icon: Icon(Icons.calendar_today_rounded, size: 16.sp),
                    label: Text(
                      'Date: ${DateFormat('EEE, MMM d, yyyy').format(selectedDate)}',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  const Text(
                    'Available Time Slots:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: slots.map((s) {
                      final isSelected = selectedSlot == s.time;
                      return ChoiceChip(
                        label: Text(s.time),
                        selected: isSelected,
                        onSelected: s.isAvailable
                            ? (val) => setModalState(() => selectedSlot = s.time)
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
                                    content: Text('Appointment rescheduled successfully!'),
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isAccepted = booking.status == BookingStatus.confirmed;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(booking: booking),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: booking.serviceImageUrl.trim().isEmpty
                        ? Container(
                            width: 60.w,
                            height: 60.h,
                            color: Colors.grey.shade300,
                            child: Icon(Icons.image_not_supported_outlined, size: 24.sp, color: Colors.grey.shade600),
                          )
                        : CachedNetworkImage(
                            imageUrl: booking.serviceImageUrl,
                            width: 60.w,
                            height: 60.h,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 60.w,
                              height: 60.h,
                              color: Colors.grey.shade200,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 60.w,
                              height: 60.h,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.image_not_supported_outlined, size: 24.sp, color: Colors.grey.shade600),
                            ),
                          ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.id,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                          'Rs ${booking.servicePrice.toStringAsFixed(0)} • ${booking.durationMinutes}m',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24.h),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 15.sp, color: theme.colorScheme.primary),
                  SizedBox(width: 8.w),
                  Text(
                    booking.bookingDate,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 16.w),
                  Icon(Icons.schedule_rounded,
                      size: 15.sp, color: theme.colorScheme.secondary),
                  SizedBox(width: 8.w),
                  Text(
                    '${booking.startTime} - ${booking.endTime}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (booking.customerNotes != null && booking.customerNotes!.trim().isNotEmpty) ...[
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(50),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    booking.customerNotes!,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.sp),
                  ),
                ),
              ],
              if (isUpcoming || isAccepted) ...[
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                        ),
                        onPressed: () => _showCancelDialog(context),
                        child: Text('Cancel', style: TextStyle(fontSize: 12.sp)),
                      ),
                    ),
                    if (isUpcoming) ...[
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                          ),
                          onPressed: () => _showRescheduleModal(context),
                          child: Text('Reschedule', style: TextStyle(fontSize: 11.sp)),
                        ),
                      ),
                    ],
                    if (isAccepted) ...[
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                          ),
                          onPressed: () async {
                            await context.read<BookingProvider>().completeBooking(booking.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking marked as completed!')),
                              );
                            }
                          },
                          child: Text('Complete', style: TextStyle(fontSize: 12.sp)),
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
