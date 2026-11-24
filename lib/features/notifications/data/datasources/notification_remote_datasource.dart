import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/network/api_endpoints.dart';
import 'package:bookease/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _client;
  NotificationRemoteDataSource(this._client);

  List<NotificationModel> _parseList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['notifications'] ?? data['data'] ?? []) as List : []);
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final res = await _client.get(ApiEndpoints.notifications);
    return _parseList(res.data);
  }

  Future<void> markAsRead(String id) async {
    await _client.patch(ApiEndpoints.readNotification(id));
  }

  Future<void> markAllAsRead() async {
    await _client.patch(ApiEndpoints.readAllNotifications);
  }

  Future<void> deleteNotification(String id) async {
    await _client.delete(ApiEndpoints.notificationById(id));
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _client.delete(ApiEndpoints.notifications);
    } catch (_) {}
  }
}
