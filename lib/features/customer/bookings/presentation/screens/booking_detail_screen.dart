import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProvider = context.read<AuthProvider>().currentUser?.isProvider ?? false;
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isAccepted = booking.status == BookingStatus.confirmed;

    Color statusColor;
    String statusLabel;
    switch (booking.status) {
      case BookingStatus.upcoming:
        statusColor = AppColors.primary;
        statusLabel = isProvider ? 'Pending Request' : 'Pending Appointment';
        break;
      case BookingStatus.confirmed:
        statusColor = Colors.blue;
        statusLabel = 'Accepted / Confirmed';
        break;
      case BookingStatus.completed:
        statusColor = AppColors.success;
        statusLabel = 'Completed';
        break;
      case BookingStatus.cancelled:
        statusColor = AppColors.error;
        statusLabel = 'Cancelled / Rejected';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #${booking.id}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge & Header Card
            Container(
              padding: EdgeInsets.all(AppSizes.s16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: booking.serviceImageUrl.isEmpty
                        ? Container(
                            width: 70.w,
                            height: 70.h,
                            color: Colors.grey.shade300,
                            child: Icon(Icons.image_not_supported_outlined, size: 28.sp),
                          )
                        : CachedNetworkImage(
                            imageUrl: booking.serviceImageUrl,
                            width: 70.w,
                            height: 70.h,
                            fit: BoxFit.cover,
                          ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          booking.serviceName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          booking.serviceCategory,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Schedule & Pricing Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule & Details',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12.h),
                    _detailRow(context, Icons.calendar_today_rounded, 'Date', booking.bookingDate),
                    SizedBox(height: 8.h),
                    _detailRow(context, Icons.schedule_rounded, 'Time', '${booking.startTime} - ${booking.endTime} (${booking.durationMinutes} mins)'),
                    SizedBox(height: 8.h),
                    _detailRow(context, Icons.payments_rounded, 'Price', 'Rs ${booking.servicePrice.toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Contact / Participant Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProvider ? 'Customer Information' : 'Service Provider',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12.h),
                    _detailRow(context, Icons.person_rounded, 'Name', booking.customerName),
                    SizedBox(height: 8.h),
                    _detailRow(context, Icons.email_rounded, 'Email', booking.customerEmail),
                    SizedBox(height: 8.h),
                    _detailRow(context, Icons.phone_rounded, 'Phone', booking.customerPhone, selectable: true),
                    if (booking.customerNotes != null && booking.customerNotes!.trim().isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      _detailRow(context, Icons.notes_rounded, 'Notes', booking.customerNotes!),
                    ],
                  ],
                ),
              ),
            ),

            if (booking.status == BookingStatus.cancelled && (booking.cancellationReason ?? '').isNotEmpty) ...[
              SizedBox(height: 20.h),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cancellation / Rejection Reason',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      SizedBox(height: 6.h),
                      Text(booking.cancellationReason!),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 32.h),

            // Actions based on role and status
            if (isProvider && isUpcoming)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () async {
                        await context.read<BookingProvider>().rejectBooking(booking.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking rejected.')),
                          );
                        }
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () async {
                        await context.read<BookingProvider>().acceptBooking(booking.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking accepted successfully!')),
                          );
                        }
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              )
            else if (!isProvider && (isUpcoming || isAccepted))
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () async {
                        await context.read<BookingProvider>().cancelBooking(booking.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking cancelled.')),
                          );
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  if (isAccepted) ...[
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: () async {
                          await context.read<BookingProvider>().completeBooking(booking.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking marked as completed!')),
                            );
                          }
                        },
                        child: const Text('Complete'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {bool selectable = false}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: theme.colorScheme.primary),
        SizedBox(width: 12.w),
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withAlpha(160)),
          ),
        ),
        Expanded(
          child: selectable
              ? SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w500))
              : Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
