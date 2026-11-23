import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/bookings/data/repositories/booking_repository.dart';
import 'package:bookease/core/services/notification_service.dart';
import 'package:bookease/core/utils/clock.dart';
import 'package:bookease/core/constants/app_constants.dart';

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
  final BookingRepository _repository;
  final NotificationService _notificationService;
  final Clock _clock;

  List<BookingModel> _all = [];
  final Set<String> _completedBookingIds = {};
  final Set<String> _confirmedBookingIds = {};
  final Set<String> _cancelledBookingIds = {};

  bool _isLoading = false;

  String? _userId;
  bool _isProvider = false;

  BookingProvider(
    this._repository,
    this._notificationService, {
    Clock? clock,
  }) : _clock = clock ?? const SystemClock() {
    _loadBookings();
  }

  void attachUser({required String? userId, required bool isProvider}) {
    if (_userId == userId && _isProvider == isProvider) return;
    _userId = userId;
    _isProvider = isProvider;
    _loadBookings();
    scheduleMicrotask(notifyListeners);
  }

  bool get isLoading => _isLoading;

  List<BookingModel> get bookings => _all
      .where((b) => b.customerId == null || b.customerId == _userId)
      .toList();

  List<BookingModel> get providerBookings => _isProvider
      ? _all
      : (_userId == null
          ? const []
          : _all.where((b) => b.providerId == null || b.providerId == _userId).toList());

  List<BookingModel> get _scope => _isProvider ? providerBookings : bookings;

  List<BookingModel> get upcomingBookings =>
      _scope.where((b) => b.status == BookingStatus.upcoming).toList()
        ..sort((a, b) => '${a.bookingDate} ${a.startTime}'
            .compareTo('${b.bookingDate} ${b.startTime}'));

  List<BookingModel> get acceptedBookings =>
      _scope.where((b) => b.status == BookingStatus.confirmed).toList()
        ..sort((a, b) => '${a.bookingDate} ${a.startTime}'
            .compareTo('${b.bookingDate} ${b.startTime}'));

  List<BookingModel> get completedBookings =>
      _scope.where((b) => b.status == BookingStatus.completed).toList()
        ..sort((a, b) => '${b.bookingDate} ${b.startTime}'
            .compareTo('${a.bookingDate} ${a.startTime}'));

  List<BookingModel> get cancelledBookings =>
      _scope.where((b) => b.status == BookingStatus.cancelled).toList()
        ..sort((a, b) => (b.cancelledAt ?? b.createdAt)
            .compareTo(a.cancelledAt ?? a.createdAt));

  double get providerEarnings => providerBookings
      .where((b) => b.status == BookingStatus.completed)
      .fold(0.0, (sum, b) => sum + b.servicePrice);

  List<BookingModel> _applyLocalStatusOverrides(List<BookingModel> list) {
    return list.map((b) {
      if (_completedBookingIds.contains(b.id)) {
        return b.copyWith(status: BookingStatus.completed);
      }
      if (_cancelledBookingIds.contains(b.id)) {
        return b.copyWith(status: BookingStatus.cancelled);
      }
      if (_confirmedBookingIds.contains(b.id)) {
        return b.copyWith(status: BookingStatus.confirmed);
      }
      return b;
    }).toList();
  }

  Future<void> _loadBookings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await _repository.getBookings(isProvider: _isProvider);
      _all = _applyLocalStatusOverrides(fetched);
    } catch (_) {
      try {
        final fetched = await _repository.getBookings();
        _all = _applyLocalStatusOverrides(fetched);
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    final activeBookingsOnDate = bookings.where((b) =>
        b.bookingDate == dateStr &&
        (b.status == BookingStatus.upcoming || b.status == BookingStatus.confirmed) &&
        b.id != excludeBookingId);

    final providerBusy = service.providerId == null
        ? const <BookingModel>[]
        : _all
            .where((b) =>
                b.providerId == service.providerId &&
                b.bookingDate == dateStr &&
                (b.status == BookingStatus.upcoming || b.status == BookingStatus.confirmed) &&
                b.id != excludeBookingId)
            .toList();

    return AppConstants.standardSlots.map((slot) {
      final slotMinutes = timeStringToMinutes(slot);
      final endTime = calculateEndTime(slot, service.durationMinutes);
      final endMinutes = timeStringToMinutes(endTime);

      if (endMinutes > 21 * 60) {
        return SlotStatus(
          time: slot,
          isAvailable: false,
          reason: 'Exceeds business hours (closes 9 PM)',
        );
      }

      if (isToday && slotMinutes <= currentMinutes + 15) {
        return SlotStatus(
          time: slot,
          isAvailable: false,
          reason: 'Time has passed',
        );
      }

      for (final other in simulatedOthers) {
        if (doIntervalsOverlap(slot, endTime, other['start']!, other['end']!)) {
          return SlotStatus(
            time: slot,
            isAvailable: false,
            reason: 'Booked by another customer',
          );
        }
      }

      for (final busy in providerBusy) {
        if (doIntervalsOverlap(slot, endTime, busy.startTime, busy.endTime)) {
          return SlotStatus(
            time: slot,
            isAvailable: false,
            reason: 'Provider is already booked',
          );
        }
      }

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

    final newBooking = BookingModel(
      id: '',
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
      customerId: _userId,
      providerId: service.providerId,
    );

    final created = await _repository.createBooking(newBooking) as dynamic;
    await _loadBookings();
    await _notificationService.scheduleBookingReminder(created is BookingModel ? created : newBooking);

    return created is BookingModel ? created : newBooking;
  }

  Future<void> acceptBooking(String bookingId) async {
    _confirmedBookingIds.add(bookingId);
    _all = _applyLocalStatusOverrides(_all);
    notifyListeners();
    try {
      await _repository.acceptBooking(bookingId);
    } catch (_) {}
    await _loadBookings();
  }

  Future<void> rejectBooking(String bookingId) async {
    _cancelledBookingIds.add(bookingId);
    _all = _applyLocalStatusOverrides(_all);
    notifyListeners();
    try {
      await _repository.rejectBooking(bookingId);
    } catch (_) {}
    await _loadBookings();
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    _cancelledBookingIds.add(bookingId);
    _all = _applyLocalStatusOverrides(_all);
    notifyListeners();
    try {
      await _repository.updateStatus(bookingId, 'CANCELLED');
    } catch (_) {}
    await _loadBookings();
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required String newDateStr,
    required String newStartTime,
  }) async {
    final index = _all.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw Exception('Booking not found');

    final current = _all[index];
    final newEndTime =
        calculateEndTime(newStartTime, current.durationMinutes);

    final updated = current.copyWith(
      bookingDate: newDateStr,
      startTime: newStartTime,
      endTime: newEndTime,
      status: BookingStatus.upcoming,
    );

    final idx = _all.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _all[idx] = updated;
    }
    notifyListeners();

    try {
      await _repository.updateBooking(updated);
    } catch (_) {}
    await _loadBookings();
  }

  Future<void> completeBooking(String bookingId) async {
    _completedBookingIds.add(bookingId);
    _all = _applyLocalStatusOverrides(_all);
    notifyListeners();
    try {
      await _repository.updateStatus(bookingId, 'COMPLETED');
    } catch (_) {}
    await _loadBookings();
  }
}
