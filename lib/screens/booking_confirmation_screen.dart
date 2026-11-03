import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/booking_model.dart';
import '../widgets/custom_button.dart';
import 'main_navigation_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
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
  }

  @override
  void dispose() {
    _animController.dispose();
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
        backgroundColor: Colors.teal.shade800,
        content: Text(
          'Appointment synced: ${widget.booking.serviceName} on ${widget.booking.bookingDate} at ${widget.booking.startTime}.',
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success animated checkmark
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withAlpha(100),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 54,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Booking Confirmed!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your service expert has been dispatched and scheduled.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Booking Reference Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_number_outlined,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Booking ID: ${booking.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Appointment Summary Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                                'Service', booking.serviceName, isBold: true),
                            const Divider(height: 20),
                            _buildSummaryRow(
                                'Scheduled Date', booking.bookingDate),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Time Slot',
                                '${booking.startTime} - ${booking.endTime}'),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Duration',
                                '${booking.durationMinutes} minutes'),
                            const Divider(height: 20),
                            _buildSummaryRow('Customer', booking.customerName),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Contact', booking.customerPhone),
                            const Divider(height: 20),
                            _buildSummaryRow(
                              'Total Amount',
                              'Rs ${booking.servicePrice.toStringAsFixed(0)}',
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Add to Calendar and Share Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: 'Add to Calendar',
                            icon: Icons.event_available_rounded,
                            isOutlined: true,
                            onPressed: _addToCalendar,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Share Summary',
                            icon: Icons.share_rounded,
                            isOutlined: true,
                            onPressed: _shareBooking,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Go to My Bookings CTA
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

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isHighlight = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight:
                  isBold || isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlight ? 16 : 14,
              color: isHighlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
