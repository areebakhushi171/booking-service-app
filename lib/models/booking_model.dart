enum BookingStatus { upcoming, completed, cancelled }

/// Booking model holding appointment details, scheduling window, and customer details
class BookingModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final String serviceImageUrl;
  final double servicePrice;
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
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      serviceCategory: json['serviceCategory'] as String,
      serviceImageUrl: json['serviceImageUrl'] as String,
      servicePrice: (json['servicePrice'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      bookingDate: json['bookingDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      customerNotes: json['customerNotes'] as String?,
      customerName: json['customerName'] as String,
      customerEmail: json['customerEmail'] as String,
      customerPhone: json['customerPhone'] as String,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.upcoming,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'serviceImageUrl': serviceImageUrl,
      'servicePrice': servicePrice,
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
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
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
    );
  }
}
