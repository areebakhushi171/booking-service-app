import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:bookease/core/constants/app_sizes.dart';
import 'package:bookease/core/widgets/empty_state_view.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/provider/presentation/widgets/booking_request_card.dart';

/// Bookings customers made with this provider, split by status.
class ProviderBookingsScreen extends StatelessWidget {
  const ProviderBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Requests'),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(horizontal: 16.w),
            tabs: [
              Tab(text: 'Pending (${bookings.upcomingBookings.length})'),
              Tab(text: 'Ongoing (${bookings.acceptedBookings.length})'),
              Tab(text: 'Completed (${bookings.completedBookings.length})'),
              Tab(text: 'Cancelled (${bookings.cancelledBookings.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingList(
              items: bookings.upcomingBookings,
              emptyTitle: 'No pending booking requests',
              emptyMessage:
                  'When a customer books one of your services it will show up here as pending.',
              emptyIcon: Icons.event_available_rounded,
            ),
            _BookingList(
              items: bookings.acceptedBookings,
              emptyTitle: 'No ongoing bookings',
              emptyMessage: 'Bookings you accept will show up here as ongoing.',
              emptyIcon: Icons.work_outline_rounded,
            ),
            _BookingList(
              items: bookings.completedBookings,
              emptyTitle: 'Nothing completed yet',
              emptyMessage: 'Jobs marked as completed are listed here.',
              emptyIcon: Icons.task_alt_rounded,
            ),
            _BookingList(
              items: bookings.cancelledBookings,
              emptyTitle: 'No cancelled bookings',
              emptyMessage: 'Declined or cancelled bookings appear here.',
              emptyIcon: Icons.event_busy_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> items;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;

  const _BookingList({
    required this.items,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: AppSizes.s20, vertical: 12.h),
          itemCount: items.length,
          itemBuilder: (_, i) => BookingRequestCard(booking: items[i]),
        ),
      ),
    );
  }
}
