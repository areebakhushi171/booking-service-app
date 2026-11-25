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
  Future<ProviderDashboardSummary> getProviderDashboardSummary() {
    return _remote.fetchProviderDashboardSummary();
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) {
    return _remote.createBooking(booking);
  }

  @override
  Future<void> updateBooking(BookingModel booking) async {
    await _remote.updateBooking(booking);
  }

  @override
  Future<BookingModel> acceptBooking(String id) {
    return _remote.acceptBooking(id);
  }

  @override
  Future<BookingModel> rejectBooking(String id) {
    return _remote.rejectBooking(id);
  }

  @override
  Future<BookingModel> updateStatus(String id, String status) {
    return _remote.updateStatus(id, status);
  }
}
