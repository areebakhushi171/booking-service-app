enum BookingStatus { upcoming, confirmed, completed, cancelled, rejected }

/// Booking model holding appointment details, scheduling window, and customer details
class BookingModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final String serviceImageUrl;
  final double? servicePrice;
  final int durationMinutes;
  final String bookingDate; // YYYY-MM-DD
  final String startTime; // HH:mm (24h)
  final String endTime; // HH:mm (24h)
  final String? customerNotes;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  /// Who booked (customer account) and who owns the service (provider account).
  final String? customerId;
  final String? providerId;

  const BookingModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    required this.serviceImageUrl,
    required this.servicePrice,
    required this.durationMinutes,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    this.customerNotes,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.status = BookingStatus.upcoming,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
    this.customerId,
    this.providerId,
  });

  String get formattedServicePrice => servicePrice == null
      ? 'Rs 0'
      : 'Rs ${servicePrice!.toStringAsFixed(0)}';

  static double? _parseBookingPrice(Map<String, dynamic> json) {
    final serviceMap = json['service'] is Map
        ? json['service'] as Map
        : (json['property'] is Map ? json['property'] as Map : null);

    final candidates = [
      json['servicePrice'],
      json['price'],
      json['totalPrice'],
      json['amount'],
      json['bookingAmount'],
      json['pricePerNight'],
      serviceMap?['price'],
      serviceMap?['servicePrice'],
      serviceMap?['amount'],
      serviceMap?['totalPrice'],
    ];

    for (final value in candidates) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static int _parseInt(dynamic value, [int defaultValue = 60]) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static BookingStatus _parseStatus(dynamic statusVal) {
    if (statusVal == null) return BookingStatus.upcoming;
    final s = statusVal.toString().toLowerCase();
    switch (s) {
      case 'pending':
      case 'upcoming':
        return BookingStatus.upcoming;
      case 'confirmed':
      case 'accepted':
      case 'approved':
        return BookingStatus.confirmed;
      case 'completed':
      case 'done':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'declined':
      case 'rejected':
        return BookingStatus.rejected;
      default:
        return BookingStatus.upcoming;
    }
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      serviceId: (json['serviceId'] ?? json['propertyId'] ?? '').toString(),
      serviceName: (json['serviceName'] ??
              json['property']?['name'] ??
              json['service']?['name'] ??
              '')
          .toString(),
      serviceCategory: (json['serviceCategory'] ??
              json['property']?['category'] ??
              json['service']?['category'] ??
              '')
          .toString(),
      serviceImageUrl: (json['serviceImageUrl'] ??
              json['property']?['imageUrl'] ??
              json['property']?['mainImageUrl'] ??
              json['property']?['coverImage'] ??
              json['service']?['imageUrl'] ??
              json['service']?['mainImageUrl'] ??
              json['service']?['coverImage'] ??
              json['service']?['mainImage'] ??
              json['imageUrl'] ??
              '')
          .toString(),
      servicePrice: _parseBookingPrice(json),
      durationMinutes: _parseInt(
          json['durationMinutes'] ??
              json['property']?['durationMinutes'] ??
              json['service']?['durationMinutes'],
          60),
      bookingDate: (json['bookingDate'] ??
              (json['startDate'] != null
                  ? json['startDate'].toString().split('T')[0]
                  : ''))
          .toString(),
      startTime: (json['startTime'] ??
              (json['startDate'] != null &&
                      json['startDate'].toString().contains('T')
                  ? json['startDate'].toString().split('T')[1].substring(0, 5)
                  : '09:00'))
          .toString(),
      endTime: (json['endTime'] ??
              (json['endDate'] != null &&
                      json['endDate'].toString().contains('T')
                  ? json['endDate'].toString().split('T')[1].substring(0, 5)
                  : '10:00'))
          .toString(),
      customerNotes: json['customerNotes']?.toString(),
      customerName: (json['customerName'] ??
              json['customer']?['name'] ??
              json['user']?['name'] ??
              '')
          .toString(),
      customerEmail: (json['customerEmail'] ??
              json['customer']?['email'] ??
              json['user']?['email'] ??
              '')
          .toString(),
      customerPhone: (json['customerPhone'] ??
              json['customer']?['phone'] ??
              json['user']?['phone'] ??
              '')
          .toString(),
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      cancellationReason: json['cancellationReason']?.toString(),
      customerId:
          (json['customerId'] ?? json['customer']?['id'] ?? json['userId'])
              ?.toString(),
      providerId: (json['providerId'] ??
              json['service']?['providerId'] ??
              json['property']?['ownerId'] ??
              json['property']?['providerId'] ??
              json['ownerId'] ??
              json['owner']?['id'])
          ?.toString(),
    );
  }

  String _toIso(String dateStr, String timeStr) {
    try {
      final dt = DateTime.parse('${dateStr.trim()}T${timeStr.trim()}:00');
      return dt.toIso8601String();
    } catch (_) {
      return DateTime.now().toIso8601String();
    }
  }

  Map<String, dynamic> toCreateRequestJson() => {
        'serviceId': serviceId,
        'startDate': _toIso(bookingDate, startTime),
        'endDate': _toIso(bookingDate, endTime),
      };

  Map<String, dynamic> toJson() {
    final startIso = _toIso(bookingDate, startTime);
    final endIso = _toIso(bookingDate, endTime);
    return {
      'id': id,
      'serviceId': serviceId,
      'propertyId': serviceId,
      'startDate': startIso,
      'endDate': endIso,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'serviceImageUrl': serviceImageUrl,
      if (servicePrice != null) 'servicePrice': servicePrice,
      'durationMinutes': durationMinutes,
      'bookingDate': bookingDate,
      'startTime': startTime,
      'endTime': endTime,
      'customerNotes': customerNotes,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (customerId != null) 'customerId': customerId,
      if (providerId != null) 'providerId': providerId,
    };
  }

  BookingModel copyWith({
    String? id,
    String? serviceId,
    String? serviceName,
    String? serviceCategory,
    String? serviceImageUrl,
    double? servicePrice,
    int? durationMinutes,
    String? bookingDate,
    String? startTime,
    String? endTime,
    String? customerNotes,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? customerId,
    String? providerId,
  }) {
    return BookingModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceImageUrl: serviceImageUrl ?? this.serviceImageUrl,
      servicePrice: servicePrice ?? this.servicePrice,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      customerNotes: customerNotes ?? this.customerNotes,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
    );
  }
}

class ProviderDashboardSummary {
  final double totalEarnings;
  final int completedBookingsCount;
  final int pendingBookingsCount;
  final int acceptedBookingsCount;
  final int totalBookingsCount;

  const ProviderDashboardSummary({
    required this.totalEarnings,
    required this.completedBookingsCount,
    required this.pendingBookingsCount,
    required this.acceptedBookingsCount,
    required this.totalBookingsCount,
  });

  factory ProviderDashboardSummary.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
      throw const FormatException('Dashboard earnings are missing or invalid');
    }

    int parseCount(dynamic value) {
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
      throw const FormatException(
          'Dashboard booking count is missing or invalid');
    }

    return ProviderDashboardSummary(
      totalEarnings: parseAmount(json['totalEarnings']),
      completedBookingsCount: parseCount(json['completedBookingsCount']),
      pendingBookingsCount: parseCount(json['pendingBookingsCount']),
      acceptedBookingsCount: parseCount(json['acceptedBookingsCount']),
      totalBookingsCount: parseCount(json['totalBookingsCount']),
    );
  }
}
