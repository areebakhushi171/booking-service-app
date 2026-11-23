import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/bookings/presentation/screens/booking_detail_screen.dart';

/// One incoming booking on the provider side, with Accept / Reject actions
/// while the booking is still upcoming/pending.
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

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.upcoming:
        return AppColors.primary;
      case BookingStatus.confirmed:
        return Colors.blue;
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
        title: const Text('Reject this booking?'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Reason (optional) - shown to the customer',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
      ),
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
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(width: AppSizes.s8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      _statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.s12),
              _InfoRow(
                icon: Icons.event_rounded,
                text:
                    '${formatDate(booking.bookingDate)}  |  ${formatTime(booking.startTime)} - ${formatTime(booking.endTime)}',
              ),
              SizedBox(height: 6.h),
              _InfoRow(icon: Icons.person_rounded, text: booking.customerName),
              SizedBox(height: 6.h),
              _InfoRow(
                icon: Icons.phone_rounded,
                text: booking.customerPhone,
                selectable: true,
              ),
              if ((booking.customerNotes ?? '').trim().isNotEmpty) ...[
                SizedBox(height: 6.h),
                _InfoRow(
                    icon: Icons.notes_rounded, text: booking.customerNotes!.trim()),
              ],
              if (booking.status == BookingStatus.cancelled &&
                  (booking.cancellationReason ?? '').isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  'Reason: ${booking.cancellationReason}',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
              SizedBox(height: AppSizes.s12),
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
                    OutlinedButton(
                      onPressed: () => _decline(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                    SizedBox(width: AppSizes.s8),
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.s16, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                      ),
                      child: const Text('Accept'),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selectable;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 16.sp, color: theme.colorScheme.onSurface.withAlpha(130)),
        SizedBox(width: AppSizes.s8),
        Expanded(
          child: selectable
              ? SelectableText(text, style: style)
              : Text(text, style: style),
        ),
      ],
    );
  }
}
