import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';

/// Contract for booking persistence.
abstract class BookingRepository {
  Future<List<BookingModel>> getBookings({bool isProvider = false});
  Future<ProviderDashboardSummary> getProviderDashboardSummary();
  Future<BookingModel> createBooking(BookingModel booking);
  Future<void> updateBooking(BookingModel booking);
  Future<BookingModel> acceptBooking(String id);
  Future<BookingModel> rejectBooking(String id);
  Future<BookingModel> updateStatus(String id, String status);
}
