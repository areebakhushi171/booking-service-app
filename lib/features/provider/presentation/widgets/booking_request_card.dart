import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bookease/features/provider/data/service_image_presets.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';

/// One incoming booking on the provider side with service imagery and
/// explicit Accept / Reject actions while pending.
class BookingRequestCard extends StatelessWidget {
  final BookingModel booking;

  const BookingRequestCard({super.key, required this.booking});

  static String formatTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }

  static String formatDate(String ymd) {
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }

  Color _statusColor(ThemeData theme) {
    switch (booking.status) {
      case BookingStatus.upcoming:
        return AppColors.warning;
      case BookingStatus.confirmed:
        return theme.colorScheme.secondary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.rejected:
        return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case BookingStatus.upcoming:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Accepted';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
    }
  }

  Future<void> _decline(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        icon: CircleAvatar(
          radius: 28.r,
          backgroundColor: AppColors.error.withAlpha(30),
          child: Icon(Icons.close_rounded, color: AppColors.error, size: 28.sp),
        ),
        title: const Text('Reject this booking?', textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Reason (optional) - shown to the customer',
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    await context.read<BookingProvider>().rejectBooking(booking.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected.')),
      );
    }
  }

  Future<void> _accept(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept this booking?'),
        content: const Text('The customer will see this booking as accepted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<BookingProvider>().acceptBooking(booking.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withAlpha(150);
    final isUpcoming = booking.status == BookingStatus.upcoming;

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.s12),
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
          padding: EdgeInsets.all(AppSizes.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: CachedNetworkImage(
                      imageUrl: booking.serviceImageUrl.trim().isNotEmpty
                          ? booking.serviceImageUrl.trim()
                          : ServiceImagePresets.forCategory(
                              booking.serviceCategory),
                      width: 68.r,
                      height: 68.r,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 68.r,
                        height: 68.r,
                        color: theme.colorScheme.onSurface.withAlpha(12),
                        child: const Icon(Icons.image_outlined),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 68.r,
                        height: 68.r,
                        color: theme.colorScheme.onSurface.withAlpha(12),
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6.h),
                        StatusPill(
                            label: _statusLabel, color: _statusColor(theme)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s12),
              InfoRow(
                icon: Icons.event_rounded,
                label: 'When',
                value:
                    '${formatDate(booking.bookingDate)}  |  ${formatTime(booking.startTime)} - ${formatTime(booking.endTime)}',
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: theme.colorScheme.secondary.withAlpha(18),
                    child: Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.secondary,
                      size: 21.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Customer',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                booking.customerName.trim().isNotEmpty
                                    ? booking.customerName
                                    : 'Not provided',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((booking.customerNotes ?? '').trim().isNotEmpty) ...[
                SizedBox(height: 10.h),
                InfoRow(
                  icon: Icons.notes_rounded,
                  label: 'Notes',
                  value: booking.customerNotes!.trim(),
                  color: muted,
                ),
              ],
              if (booking.status == BookingStatus.cancelled &&
                  (booking.cancellationReason ?? '').isNotEmpty) ...[
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(18),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Reason: ${booking.cancellationReason}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
              Divider(height: 26.h),
              Row(
                children: [
                  Text(
                    booking.formattedServicePrice,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (isUpcoming) ...[
                    OutlinedButton.icon(
                      onPressed: () => _decline(context),
                      icon: Icon(Icons.close_rounded, size: 18.sp),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        backgroundColor: AppColors.error.withAlpha(14),
                        side: BorderSide(color: AppColors.error.withAlpha(55)),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        textStyle: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    FilledButton.icon(
                      onPressed: () => _accept(context),
                      icon: Icon(Icons.check_rounded, size: 18.sp),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success.withAlpha(22),
                        foregroundColor: AppColors.success,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        textStyle: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
