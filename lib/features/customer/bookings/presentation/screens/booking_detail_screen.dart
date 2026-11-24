import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProvider =
        context.read<AuthProvider>().currentUser?.isProvider ?? false;
    final isUpcoming = booking.status == BookingStatus.upcoming;
    final isAccepted = booking.status == BookingStatus.confirmed;
    final isCancelled = booking.status == BookingStatus.cancelled;

    Color statusColor;
    String statusLabel;
    int trackerStep;
    switch (booking.status) {
      case BookingStatus.upcoming:
        statusColor = AppColors.warning;
        statusLabel = isProvider ? 'Pending Request' : 'Pending Appointment';
        trackerStep = 0;
        break;
      case BookingStatus.confirmed:
        statusColor = theme.colorScheme.secondary;
        statusLabel = 'Accepted / Confirmed';
        trackerStep = 1;
        break;
      case BookingStatus.completed:
        statusColor = AppColors.success;
        statusLabel = 'Completed';
        trackerStep = 2;
        break;
      case BookingStatus.cancelled:
        statusColor = AppColors.error;
        statusLabel = 'Cancelled / Rejected';
        trackerStep = -1;
        break;
    }

    final showActions =
        (isProvider && isUpcoming) || (!isProvider && (isUpcoming || isAccepted));

    return Scaffold(
      appBar: AppBar(title: Text('Booking #${booking.id}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeSlideIn(
                  child: Container(
                    padding: EdgeInsets.all(AppSizes.s16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                          color: theme.colorScheme.onSurface.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: booking.serviceImageUrl.isEmpty
                              ? Container(
                            width: 76.r,
                            height: 76.r,
                            color: Colors.grey.withAlpha(50),
                            child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 28.sp),
                          )
                              : CachedNetworkImage(
                            imageUrl: booking.serviceImageUrl,
                            width: 76.r,
                            height: 76.r,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusPill(label: statusLabel, color: statusColor),
                              SizedBox(height: 8.h),
                              Text(
                                booking.serviceName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                booking.serviceCategory,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                  theme.colorScheme.onSurface.withAlpha(160),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Tracker
                if (!isCancelled)
                  FadeSlideIn(
                    index: 1,
                    child: SectionCard(
                      title: 'Booking Progress',
                      icon: Icons.timeline_rounded,
                      child: _StatusTracker(current: trackerStep),
                    ),
                  ),
                if (!isCancelled) SizedBox(height: 16.h),

                // Schedule
                FadeSlideIn(
                  index: 2,
                  child: SectionCard(
                    title: 'Schedule & Details',
                    icon: Icons.event_note_rounded,
                    child: Column(
                      children: [
                        InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: booking.bookingDate,
                        ),
                        SizedBox(height: 12.h),
                        InfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Time',
                          value:
                          '${booking.startTime} - ${booking.endTime} (${booking.durationMinutes} mins)',
                          color: theme.colorScheme.secondary,
                        ),
                        SizedBox(height: 12.h),
                        InfoRow(
                          icon: Icons.payments_rounded,
                          label: 'Price',
                          value: 'Rs ${booking.servicePrice.toStringAsFixed(0)}',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Contact
                FadeSlideIn(
                  index: 3,
                  child: SectionCard(
                    title: isProvider ? 'Customer Information' : 'Service Provider',
                    icon: Icons.person_rounded,
                    child: Column(
                      children: [
                        InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Name',
                          value: booking.customerName,
                        ),
                        SizedBox(height: 12.h),
                        InfoRow(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: booking.customerEmail,
                          trailing: CircleActionButton(
                            icon: Icons.copy_rounded,
                            tooltip: 'Copy email',
                            size: 36.r,
                            onPressed: () => copyToClipboard(
                                context, booking.customerEmail,
                                message: 'Email copied'),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        InfoRow(
                          icon: Icons.phone_rounded,
                          label: 'Phone',
                          value: booking.customerPhone,
                          selectable: true,
                          trailing: CircleActionButton(
                            icon: Icons.copy_rounded,
                            tooltip: 'Copy phone number',
                            size: 36.r,
                            onPressed: () => copyToClipboard(
                                context, booking.customerPhone,
                                message: 'Phone number copied'),
                          ),
                        ),
                        if (booking.customerNotes != null &&
                            booking.customerNotes!.trim().isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          InfoRow(
                            icon: Icons.notes_rounded,
                            label: 'Notes',
                            value: booking.customerNotes!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (isCancelled &&
                    (booking.cancellationReason ?? '').isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  SectionCard(
                    title: 'Cancellation / Rejection Reason',
                    icon: Icons.info_outline_rounded,
                    tint: AppColors.error,
                    child: Text(booking.cancellationReason!),
                  ),
                ],

                if (showActions) ...[
                  SizedBox(height: 28.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isProvider && isUpcoming) ...[
                        CircleActionButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Reject booking',
                          label: 'Reject',
                          color: AppColors.error,
                          size: 58.r,
                          onPressed: () async {
                            await context
                                .read<BookingProvider>()
                                .rejectBooking(booking.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Booking rejected.')),
                              );
                            }
                          },
                        ),
                        SizedBox(width: 36.w),
                        CircleActionButton(
                          icon: Icons.check_rounded,
                          tooltip: 'Accept booking',
                          label: 'Accept',
                          color: AppColors.success,
                          size: 58.r,
                          onPressed: () async {
                            await context
                                .read<BookingProvider>()
                                .acceptBooking(booking.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                    Text('Booking accepted successfully!')),
                              );
                            }
                          },
                        ),
                      ] else ...[
                        CircleActionButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Cancel booking',
                          label: 'Cancel',
                          color: AppColors.error,
                          size: 58.r,
                          onPressed: () async {
                            await context
                                .read<BookingProvider>()
                                .cancelBooking(booking.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Booking cancelled.')),
                              );
                            }
                          },
                        ),
                        if (isAccepted) ...[
                          SizedBox(width: 36.w),
                          CircleActionButton(
                            icon: Icons.check_rounded,
                            tooltip: 'Mark as completed',
                            label: 'Complete',
                            color: AppColors.success,
                            size: 58.r,
                            onPressed: () async {
                              await context
                                  .read<BookingProvider>()
                                  .completeBooking(booking.id);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                      Text('Booking marked as completed!')),
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  final int current; // 0 pending, 1 accepted, 2 completed

  const _StatusTracker({required this.current});

  static const _labels = ['Pending', 'Accepted', 'Completed'];
  static const _icons = [
    Icons.hourglass_top_rounded,
    Icons.thumb_up_alt_rounded,
    Icons.verified_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final off = theme.colorScheme.onSurface.withAlpha(35);
    final dim = 36.r;

    final children = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final done = i <= current;
      children.add(
        SizedBox(
          width: 66.w,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: dim,
                height: dim,
                decoration: BoxDecoration(
                  color: done ? primary : off,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  i < current ? Icons.check_rounded : _icons[i],
                  size: 18.sp,
                  color: done
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                  color: done
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
      );
      if (i < 2) {
        children.add(
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: dim / 2 - 1.5),
              height: 3,
              decoration: BoxDecoration(
                color: i < current ? primary : off,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}