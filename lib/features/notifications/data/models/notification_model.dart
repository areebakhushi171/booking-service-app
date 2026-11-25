class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final String? referenceId;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.type,
    this.referenceId,
    this.data,
  });

  static bool _parseRead(Map<String, dynamic> json) {
    if (json['isRead'] == true || json['read'] == true) return true;
    if (json['status'] != null &&
        json['status'].toString().toUpperCase() == 'READ') return true;
    if (json['readAt'] != null &&
        json['readAt'].toString().isNotEmpty &&
        json['readAt'].toString() != 'null') return true;
    return false;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? rawData.map((key, value) => MapEntry(key.toString(), value))
        : null;
    return NotificationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: _parseRead(json),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: json['type']?.toString(),
      referenceId: (json['referenceId'] ??
              data?['bookingId'] ??
              data?['messageId'] ??
              data?['serviceId'])
          ?.toString(),
      data: data,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'type': type,
        'referenceId': referenceId,
        'data': data,
      };

  NotificationModel copyWith({
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      type: type,
      referenceId: referenceId,
      data: data ?? this.data,
    );
  }
}
