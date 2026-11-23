import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';

/// Contract for booking persistence.
abstract class BookingRepository {
  Future<List<BookingModel>> getBookings({bool isProvider = false});
  Future<void> createBooking(BookingModel booking);
  Future<void> updateBooking(BookingModel booking);
  Future<void> acceptBooking(String id);
  Future<void> rejectBooking(String id);
  Future<void> updateStatus(String id, String status);
}
