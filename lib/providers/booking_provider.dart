import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../models/service_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../utils/clock.dart';
import '../utils/constants.dart';

class SlotStatus {
  final String time;
  final bool isAvailable;
  final String? reason;

  const SlotStatus({
    required this.time,
    required this.isAvailable,
    this.reason,
  });
}

class BookingProvider extends ChangeNotifier {
  final StorageService _storageService;
  final NotificationService _notificationService;
  final Clock _clock;

  List<BookingModel> _bookings = [];
  bool _isLoading = false;

  BookingProvider(
    this._storageService,
    this._notificationService, {
    Clock? clock,
  }) : _clock = clock ?? const SystemClock() {
    _loadBookings();
  }

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;

  List<BookingModel> get upcomingBookings =>
      _bookings.where((b) => b.status == BookingStatus.upcoming).toList()
        ..sort((a, b) => '${a.bookingDate} ${a.startTime}'
            .compareTo('${b.bookingDate} ${b.startTime}'));

  List<BookingModel> get completedBookings =>
      _bookings.where((b) => b.status == BookingStatus.completed).toList()
        ..sort((a, b) => '${b.bookingDate} ${b.startTime}'
            .compareTo('${a.bookingDate} ${a.startTime}'));

  List<BookingModel> get cancelledBookings =>
      _bookings.where((b) => b.status == BookingStatus.cancelled).toList()
        ..sort((a, b) => (b.cancelledAt ?? b.createdAt)
            .compareTo(a.cancelledAt ?? a.createdAt));

  void _loadBookings() {
    _bookings = _storageService.getBookings();
    notifyListeners();
  }

  // --- Date & Time Calculation Helpers ---
  static int timeStringToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = parts.length > 1 ? int.parse(parts[1]) : 0;
    return hours * 60 + minutes;
  }

  static String minutesToTimeString(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  static String calculateEndTime(String startTime, int durationMinutes) {
    final startMins = timeStringToMinutes(startTime);
    return minutesToTimeString(startMins + durationMinutes);
  }

  /// Check whether two time intervals overlap on the same day:
  /// Interval A: [startA, endA)
  /// Interval B: [startB, endB)
  static bool doIntervalsOverlap(
    String startA,
    String endA,
    String startB,
    String endB,
  ) {
    final aStart = timeStringToMinutes(startA);
    final aEnd = timeStringToMinutes(endA);
    final bStart = timeStringToMinutes(startB);
    final bEnd = timeStringToMinutes(endB);

    return max(aStart, bStart) < min(aEnd, bEnd);
  }

  /// Generate deterministic simulated slots taken by other customers on that date
  List<Map<String, String>> getSimulatedOtherBookings(String dateStr) {
    int hash = 0;
    for (int i = 0; i < dateStr.length; i++) {
      hash = (hash * 31 + dateStr.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final slots = AppConstants.standardSlots;
    final index1 = hash % slots.length;
    final index2 = (hash + 4) % slots.length;

    final result = <Map<String, String>>[];
    final slot1 = slots[index1];
    result.add({'start': slot1, 'end': calculateEndTime(slot1, 60)});

    if (index2 != index1) {
      final slot2 = slots[index2];
      result.add({'start': slot2, 'end': calculateEndTime(slot2, 60)});
    }
    return result;
  }

  /// Evaluate availability of standard slots for a chosen service on a specific date
  List<SlotStatus> getSlotStatuses({
    required String dateStr,
    required ServiceModel service,
    String? excludeBookingId,
  }) {
    final now = _clock.now();
    final todayStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isToday = dateStr == todayStr;
    final currentMinutes = now.hour * 60 + now.minute;

    final simulatedOthers = getSimulatedOtherBookings(dateStr);
    final activeBookingsOnDate = _bookings.where((b) =>
        b.bookingDate == dateStr &&
        b.status == BookingStatus.upcoming &&
        b.id != excludeBookingId);

    return AppConstants.standardSlots.map((slot) {
      final slotMinutes = timeStringToMinutes(slot);
      final endTime = calculateEndTime(slot, service.durationMinutes);
      final endMinutes = timeStringToMinutes(endTime);

      // 1. Outside operational hours (closing at 21:00 / 9 PM)
      if (endMinutes > 21 * 60) {
        return SlotStatus(
          time: slot,
          isAvailable: false,
          reason: 'Exceeds business hours (closes 9 PM)',
        );
      }

      // 2. Past time check (with 15 min buffer if booking for today)
      if (isToday && slotMinutes <= currentMinutes + 15) {
        return SlotStatus(
          time: slot,
          isAvailable: false,
          reason: 'Time has passed',
        );
      }

      // 3. Conflict with simulated other customers
      for (final other in simulatedOthers) {
        if (doIntervalsOverlap(slot, endTime, other['start']!, other['end']!)) {
          return SlotStatus(
            time: slot,
            isAvailable: false,
            reason: 'Booked by another customer',
          );
        }
      }

      // 4. Double booking / Overlap with user's own bookings
      for (final existing in activeBookingsOnDate) {
        if (doIntervalsOverlap(
            slot, endTime, existing.startTime, existing.endTime)) {
          return SlotStatus(
            time: slot,
            isAvailable: false,
            reason: 'Overlaps with your booking for ${existing.serviceName}',
          );
        }
      }

      return SlotStatus(time: slot, isAvailable: true);
    }).toList();
  }

  /// Create a new booking
  Future<BookingModel> createBooking({
    required ServiceModel service,
    required String dateStr,
    required String startTime,
    String? customerNotes,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    final endTime = calculateEndTime(startTime, service.durationMinutes);

    // Business rule validation: Double check conflicts before writing
    final conflicts = _bookings.where((b) =>
        b.bookingDate == dateStr &&
        b.status == BookingStatus.upcoming &&
        doIntervalsOverlap(startTime, endTime, b.startTime, b.endTime));

    if (conflicts.isNotEmpty) {
      throw Exception(
        'Time slot conflict: You already have a booking (${conflicts.first.serviceName}) during this period.',
      );
    }

    final randNum = 1000 + Random().nextInt(9000);
    final bookingId = 'BK-$randNum';

    final newBooking = BookingModel(
      id: bookingId,
      serviceId: service.id,
      serviceName: service.name,
      serviceCategory: service.category,
      serviceImageUrl: service.imageUrl,
      servicePrice: service.price,
      durationMinutes: service.durationMinutes,
      bookingDate: dateStr,
      startTime: startTime,
      endTime: endTime,
      customerNotes: customerNotes,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      status: BookingStatus.upcoming,
      createdAt: _clock.now(),
    );

    _bookings.insert(0, newBooking);
    notifyListeners();

    await _storageService.saveBookings(_bookings);
    await _notificationService.scheduleBookingReminder(newBooking);

    return newBooking;
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw Exception('Booking not found');

    final updated = _bookings[index].copyWith(
      status: BookingStatus.cancelled,
      cancelledAt: _clock.now(),
      cancellationReason: reason ?? 'Cancelled by customer',
    );

    _bookings[index] = updated;
    notifyListeners();

    await _storageService.saveBookings(_bookings);
    await _notificationService.cancelReminder(bookingId);
  }

  /// Reschedule an existing booking to new date & time
  Future<void> rescheduleBooking({
    required String bookingId,
    required String newDateStr,
    required String newStartTime,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw Exception('Booking not found');

    final current = _bookings[index];
    final newEndTime =
        calculateEndTime(newStartTime, current.durationMinutes);

    // Check conflicts excluding this booking
    final conflicts = _bookings.where((b) =>
        b.id != bookingId &&
        b.bookingDate == newDateStr &&
        b.status == BookingStatus.upcoming &&
        doIntervalsOverlap(newStartTime, newEndTime, b.startTime, b.endTime));

    if (conflicts.isNotEmpty) {
      throw Exception('Selected slot conflicts with an existing booking.');
    }

    final updated = current.copyWith(
      bookingDate: newDateStr,
      startTime: newStartTime,
      endTime: newEndTime,
      status: BookingStatus.upcoming,
    );

    _bookings[index] = updated;
    notifyListeners();

    await _storageService.saveBookings(_bookings);
    await _notificationService.scheduleBookingReminder(updated);
  }

  /// Mark booking as completed
  Future<void> completeBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] =
          _bookings[index].copyWith(status: BookingStatus.completed);
      notifyListeners();
      await _storageService.saveBookings(_bookings);
    }
  }
}
