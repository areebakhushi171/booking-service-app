import 'package:bookease/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:bookease/features/notifications/data/models/notification_model.dart';

class NotificationRepository {
  final NotificationRemoteDataSource _source;
  NotificationRepository(this._source);

  Future<List<NotificationModel>> fetchNotifications() => _source.fetchNotifications();
  Future<void> markAsRead(String id) => _source.markAsRead(id);
  Future<void> markAllAsRead() => _source.markAllAsRead();
  Future<void> deleteNotification(String id) => _source.deleteNotification(id);
  Future<void> deleteAllNotifications() => _source.deleteAllNotifications();
}
