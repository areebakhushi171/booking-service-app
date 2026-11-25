import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/network/api_endpoints.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';

class BookingRemoteDataSource {
  final ApiClient _client;
  BookingRemoteDataSource(this._client);

  List<BookingModel> _parseList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['bookings'] ?? data['data'] ?? []) as List : []);
    return list
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  BookingModel _parseSingle(dynamic data) {
    final json = data is Map
        ? (data['booking'] ?? data['data'] ?? data) as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return BookingModel.fromJson(json);
  }

  Future<List<BookingModel>> fetchBookings({bool isProvider = false}) async {
    final firstChoice =
        isProvider ? ApiEndpoints.receivedBookings : ApiEndpoints.myBookings;
    final fallbackChoice =
        isProvider ? ApiEndpoints.myBookings : ApiEndpoints.receivedBookings;

    try {
      final res = await _client.get(firstChoice);
      return _parseList(res.data);
    } catch (_) {
      try {
        final res = await _client.get(fallbackChoice);
        return _parseList(res.data);
      } catch (_) {
        return [];
      }
    }
  }

  Future<ProviderDashboardSummary> fetchProviderDashboardSummary() async {
    final response = await _client.get(ApiEndpoints.providerBookingDashboard);
    final data = response.data;
    final json = data is Map && data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
    return ProviderDashboardSummary.fromJson(json);
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    final res = await _client.post(
      ApiEndpoints.bookings,
      body: booking.toCreateRequestJson(),
    );
    return _parseSingle(res.data);
  }

  Future<BookingModel> updateBooking(BookingModel booking) async {
    final res = await _client.patch(ApiEndpoints.bookingById(booking.id),
        body: booking.toJson());
    return _parseSingle(res.data);
  }

  Future<BookingModel> cancelBooking(String id, {String? reason}) async {
    final res = await _client.patch(ApiEndpoints.cancelBooking(id),
        body: {'reason': reason ?? 'Cancelled'});
    return _parseSingle(res.data);
  }

  Future<BookingModel> acceptBooking(String id) async {
    final res = await _client.patch(ApiEndpoints.acceptBooking(id));
    return _parseSingle(res.data);
  }

  Future<BookingModel> rejectBooking(String id) async {
    final res = await _client.patch(ApiEndpoints.rejectBooking(id));
    return _parseSingle(res.data);
  }

  Future<BookingModel> updateStatus(String id, String status) async {
    final uppercaseStatus = status.toUpperCase();
    final res = await _client.patch(
      ApiEndpoints.bookingStatus(id),
      body: {'status': uppercaseStatus},
    );
    return _parseSingle(res.data);
  }
}
