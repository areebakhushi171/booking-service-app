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
  final Set<String> _inFlightBookingIds = {};
  bool _isLoading = false;
  bool _isDashboardLoading = false;
  ProviderDashboardSummary? _dashboardSummary;
  String? _dashboardError;
  String? _errorMessage;

  String? _userId;
  bool _isProvider = false;

  BookingProvider(
    this._repository,
    this._notificationService, {
    Clock? clock,
  }) : _clock = clock ?? const SystemClock();

  void attachUser({required String? userId, required bool isProvider}) {
    if (_userId == userId && _isProvider == isProvider) return;
    _userId = userId;
    _isProvider = isProvider;
    if (userId != null && userId.isNotEmpty) {
      unawaited(_loadBookings());
      if (isProvider) {
        unawaited(loadProviderDashboardSummary());
      }
    } else {
      _all = [];
      _dashboardSummary = null;
    }
    scheduleMicrotask(notifyListeners);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDashboardLoading => _isDashboardLoading;
  ProviderDashboardSummary? get dashboardSummary => _dashboardSummary;
  String? get dashboardError => _dashboardError;

  List<BookingModel> get bookings => _all
      .where((b) => b.customerId == null || b.customerId == _userId)
      .toList();

  List<BookingModel> get providerBookings => _isProvider && _userId != null
      ? _all.where((booking) => booking.providerId == _userId).toList()
      : const [];

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
            .compareTo('${a.bookingDate} ${b.startTime}'));

  List<BookingModel> get cancelledBookings => _scope
      .where((b) =>
          b.status == BookingStatus.cancelled ||
          b.status == BookingStatus.rejected)
      .toList()
    ..sort((a, b) =>
        (b.cancelledAt ?? b.createdAt).compareTo(a.cancelledAt ?? a.createdAt));

  Future<void> _loadBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final fetched = await _repository.getBookings(isProvider: _isProvider);
      _all = fetched;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBookings() => _loadBookings();

  Future<void> loadProviderDashboardSummary() async {
    if (!_isProvider || _userId == null) return;
    _isDashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboardSummary = await _repository.getProviderDashboardSummary();
    } catch (error) {
      _dashboardError = error.toString();
    } finally {
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  void handleRealtimeBooking(Map<String, dynamic> payload) {
    final rawBooking = payload['booking'];
    if (rawBooking is! Map) return;
    final booking = BookingModel.fromJson(
      rawBooking.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (booking.id.isEmpty) return;

    if (_userId != null &&
        booking.customerId != _userId &&
        booking.providerId != _userId) {
      return;
    }

    final index = _all.indexWhere((item) => item.id == booking.id);
    if (index != -1 && mapEquals(_all[index].toJson(), booking.toJson())) {
      return;
    }
    final shouldRefreshDashboard =
        _isProvider && (index == -1 || _all[index].status != booking.status);
    if (index == -1) {
      _all.insert(0, booking);
    } else {
      _all[index] = booking;
    }
    notifyListeners();
    if (shouldRefreshDashboard) {
      unawaited(loadProviderDashboardSummary());
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
        (b.status == BookingStatus.upcoming ||
            b.status == BookingStatus.confirmed) &&
        b.id != excludeBookingId);

    final providerBusy = service.providerId == null
        ? const <BookingModel>[]
        : _all
            .where((b) =>
                b.providerId == service.providerId &&
                b.bookingDate == dateStr &&
                (b.status == BookingStatus.upcoming ||
                    b.status == BookingStatus.confirmed) &&
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

    final created = await _repository.createBooking(newBooking);
    _upsertBooking(created);
    await _loadBookings();
    await _notificationService.scheduleBookingReminder(created);
    return created;
  }

  Future<void> acceptBooking(String bookingId) async {
    final booking = await _repository.acceptBooking(bookingId);
    _upsertBooking(booking);
    await _loadBookings();
    if (_isProvider) await loadProviderDashboardSummary();
  }

  Future<void> rejectBooking(String bookingId) async {
    final booking = await _repository.rejectBooking(bookingId);
    _upsertBooking(booking);
    await _loadBookings();
    if (_isProvider) await loadProviderDashboardSummary();
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final booking = await _repository.updateStatus(bookingId, 'CANCELLED');
    _upsertBooking(booking);
    await _loadBookings();
    if (_isProvider) await loadProviderDashboardSummary();
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required String newDateStr,
    required String newStartTime,
  }) async {
    final index = _all.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw Exception('Booking not found');

    final current = _all[index];
    final newEndTime = calculateEndTime(newStartTime, current.durationMinutes);

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

  bool isBookingInFlight(String bookingId) =>
      _inFlightBookingIds.contains(bookingId);

  Future<void> completeBooking(String bookingId) async {
    if (bookingId.isEmpty) return;
    if (_inFlightBookingIds.contains(bookingId)) return;

    final existingIndex = _all.indexWhere((b) => b.id == bookingId);
    if (existingIndex != -1) {
      final target = _all[existingIndex];
      if (target.status != BookingStatus.confirmed) {
        throw StateError(
          'Only accepted or confirmed bookings can be marked as completed.',
        );
      }
    }

    _inFlightBookingIds.add(bookingId);
    notifyListeners();

    try {
      final booking = await _repository.updateStatus(bookingId, 'COMPLETED');
      _upsertBooking(booking);
      await _loadBookings();
      if (_isProvider) {
        await loadProviderDashboardSummary();
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _inFlightBookingIds.remove(bookingId);
      notifyListeners();
    }
  }

  void _upsertBooking(BookingModel booking) {
    if (booking.id.isEmpty) return;
    final index = _all.indexWhere((item) => item.id == booking.id);
    if (index == -1) {
      _all.insert(0, booking);
    } else {
      _all[index] = booking;
    }
    notifyListeners();
  }
}
