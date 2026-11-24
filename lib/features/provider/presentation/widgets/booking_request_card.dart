import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';

/// One incoming booking on the provider side, with circular Accept / Reject
/// actions while the booking is still upcoming/pending.
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
    }
  }

  Future<void> _decline(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
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
          MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: AppSizes.s8),
                  StatusPill(label: _statusLabel, color: _statusColor(theme)),
                ],
              ),
              SizedBox(height: AppSizes.s12),
              InfoRow(
                icon: Icons.event_rounded,
                label: 'When',
                value:
                '${formatDate(booking.bookingDate)}  |  ${formatTime(booking.startTime)} - ${formatTime(booking.endTime)}',
              ),
              SizedBox(height: 10.h),
              InfoRow(
                icon: Icons.person_rounded,
                label: 'Customer',
                value: booking.customerName,
                color: theme.colorScheme.secondary,
              ),
              SizedBox(height: 10.h),
              InfoRow(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: booking.customerPhone,
                selectable: true,
                color: AppColors.accentTeal,
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
                    'Rs ${booking.servicePrice.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (isUpcoming) ...[
                    CircleActionButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Reject booking',
                      label: 'Reject',
                      color: AppColors.error,
                      onPressed: () => _decline(context),
                    ),
                    SizedBox(width: 18.w),
                    CircleActionButton(
                      icon: Icons.check_rounded,
                      tooltip: 'Accept booking',
                      label: 'Accept',
                      color: AppColors.success,
                      onPressed: () async {
                        await context
                            .read<BookingProvider>()
                            .acceptBooking(booking.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Booking accepted successfully!')),
                          );
                        }
                      },
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