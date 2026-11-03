import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../providers/booking_provider.dart';
import '../providers/service_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_view.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsTab(status: BookingStatus.upcoming),
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
        emptyTitle = 'No Upcoming Appointments';
        emptyMessage =
            'You have no scheduled bookings at the moment. Explore services to make your first appointment!';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            const SizedBox(height: 14),
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
    DateTime selectedDate = DateTime.parse(booking.bookingDate);
    String? selectedSlot = booking.startTime;
    final bookingProvider = context.read<BookingProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    // Find service model
    final service = serviceProvider.services.firstWhere(
      (s) => s.id == booking.serviceId,
      orElse: () => ServiceModel(
        id: booking.serviceId,
        name: booking.serviceName,
        category: booking.serviceCategory,
        description: '',
        price: booking.servicePrice,
        durationMinutes: booking.durationMinutes,
        rating: 5.0,
        reviewCount: 1,
        imageUrl: booking.serviceImageUrl,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                left: 20,
                right: 20,
                top: 20,
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
                  const SizedBox(height: 12),
                  Text(
                    'Pick a new date and conflict-free slot for ${booking.serviceName}.',
                  ),
                  const SizedBox(height: 16),
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
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      'Date: ${DateFormat('EEE, MMM d, yyyy').format(selectedDate)}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Available Time Slots:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                  const SizedBox(height: 24),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: booking.serviceImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.id,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${booking.servicePrice.toStringAsFixed(0)} • ${booking.durationMinutes}m',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  booking.bookingDate,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule_rounded,
                    size: 15, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '${booking.startTime} - ${booking.endTime}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (booking.customerNotes != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.customerNotes!,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ),
            ],
            if (isUpcoming) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: () => _showCancelDialog(context),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: () => _showRescheduleModal(context),
                      child: const Text('Reschedule', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: () async {
                        await context.read<BookingProvider>().completeBooking(booking.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Booking marked as completed!')),
                          );
                        }
                      },
                      child: const Text('Complete', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
