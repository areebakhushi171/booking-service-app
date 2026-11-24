import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bookease/core/constants/app_colors.dart';
import 'package:bookease/core/widgets/circle_action_button.dart';
import 'package:bookease/core/widgets/custom_button.dart';
import 'package:bookease/core/widgets/ui_kit.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/presentation/screens/main_navigation_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _ringController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    _animController.forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _shareBooking() {
    final b = widget.booking;
    final text =
        'BookEase Booking Confirmed! Ref: ${b.id}\nService: ${b.serviceName}\nDate: ${b.bookingDate} (${b.startTime} - ${b.endTime})\nTotal: Rs ${b.servicePrice.toStringAsFixed(0)}';
    Share.share(text, subject: 'My BookEase Appointment');
  }

  void _addToCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appointment synced: ${widget.booking.serviceName} on ${widget.booking.bookingDate} at ${widget.booking.startTime}.',
        ),
      ),
    );
  }

  Widget _successBadge() {
    final size = 92.r;
    return SizedBox(
      width: size * 2.1,
      height: size * 2.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final phase in [0.0, 0.5])
            AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) {
                final t = (_ringController.value + phase) % 1.0;
                return Container(
                  width: size * (1 + t * 1.0),
                  height: size * (1 + t * 1.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withAlpha(((1 - t) * 90).toInt()),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          Container(
            width: size * 1.25,
            height: size * 1.25,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(35),
              shape: BoxShape.circle,
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withAlpha(100),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.check_rounded, size: 54.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = widget.booking;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _successBadge(),
                    SizedBox(height: 8.h),
                    Text(
                      'Booking Confirmed!',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your service expert has been dispatched and scheduled.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Ticket
                    FadeSlideIn(
                      index: 2,
                      child: _TicketCard(
                        notchColor: theme.scaffoldBackgroundColor,
                        top: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.confirmation_number_outlined,
                                    size: 18.sp,
                                    color: theme.colorScheme.primary),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    'Booking ID: ${booking.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.sp,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                CircleActionButton(
                                  icon: Icons.copy_rounded,
                                  tooltip: 'Copy booking ID',
                                  size: 36.r,
                                  onPressed: () => copyToClipboard(
                                      context, booking.id,
                                      message: 'Booking ID copied'),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            _row('Service', booking.serviceName, bold: true),
                            SizedBox(height: 10.h),
                            _row('Scheduled Date', booking.bookingDate),
                            SizedBox(height: 10.h),
                            _row('Time Slot',
                                '${booking.startTime} - ${booking.endTime}'),
                            SizedBox(height: 10.h),
                            _row('Duration', '${booking.durationMinutes} minutes'),
                          ],
                        ),
                        bottom: Column(
                          children: [
                            _row('Customer', booking.customerName),
                            SizedBox(height: 10.h),
                            _row('Contact', booking.customerPhone),
                            SizedBox(height: 14.h),
                            _row(
                              'Total Amount',
                              'Rs ${booking.servicePrice.toStringAsFixed(0)}',
                              highlight: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Circular quick actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleActionButton(
                          icon: Icons.event_available_rounded,
                          tooltip: 'Add to calendar',
                          label: 'Calendar',
                          size: 56.r,
                          onPressed: _addToCalendar,
                        ),
                        SizedBox(width: 36.w),
                        CircleActionButton(
                          icon: Icons.share_rounded,
                          tooltip: 'Share summary',
                          label: 'Share',
                          size: 56.r,
                          onPressed: _shareBooking,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'View in My Bookings',
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) =>
                              const MainNavigationScreen(initialIndex: 1),
                            ),
                                (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, bool highlight = false}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold || highlight ? FontWeight.bold : FontWeight.w600,
              fontSize: highlight ? 18.sp : 14.sp,
              color: highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ticket-style card: two sections split by a dashed line with side notches.
class _TicketCard extends StatelessWidget {
  final Widget top;
  final Widget bottom;
  final Color notchColor;

  const _TicketCard({
    required this.top,
    required this.bottom,
    required this.notchColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = 12.r;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: theme.colorScheme.onSurface.withAlpha(20)),
      ),
      child: Column(
        children: [
          Padding(padding: EdgeInsets.fromLTRB(18.r, 18.r, 18.r, 8.r), child: top),
          SizedBox(
            height: r * 2,
            child: Row(
              children: [
                Transform.translate(
                  offset: Offset(-r, 0),
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration:
                    BoxDecoration(color: notchColor, shape: BoxShape.circle),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, c) {
                      final n = (c.maxWidth / 9).floor();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          n,
                              (_) => Container(
                            width: 5,
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withAlpha(50),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Transform.translate(
                  offset: Offset(r, 0),
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration:
                    BoxDecoration(color: notchColor, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(18.r, 8.r, 18.r, 18.r), child: bottom),
        ],
      ),
    );
  }
}