import 'package:bookease/features/customer/bookings/data/datasources/booking_remote_datasource.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/data/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remote;

  BookingRepositoryImpl(this._remote);

  @override
  Future<List<BookingModel>> getBookings({bool isProvider = false}) async {
    return await _remote.fetchBookings(isProvider: isProvider);
  }

  @override
  Future<void> createBooking(BookingModel booking) async {
    await _remote.createBooking(booking);
  }

  @override
  Future<void> updateBooking(BookingModel booking) async {
    await _remote.updateBooking(booking);
  }

  @override
  Future<void> acceptBooking(String id) async {
    await _remote.acceptBooking(id);
  }

  @override
  Future<void> rejectBooking(String id) async {
    await _remote.rejectBooking(id);
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    await _remote.updateStatus(id, status);
  }
}
