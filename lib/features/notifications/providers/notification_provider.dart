import 'package:flutter/foundation.dart';
import 'package:bookease/features/notifications/data/models/notification_model.dart';
import 'package:bookease/features/notifications/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  List<NotificationModel> _notifications = [];
  final Set<String> _locallyReadIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  int? _serverUnreadCount;

  NotificationProvider(this._repository, {bool loadOnStart = true}) {
    if (loadOnStart) {
      loadNotifications();
    }
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount =>
      _serverUnreadCount ?? _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final fetched = await _repository.fetchNotifications();
      _notifications = fetched.map((n) {
        if (_locallyReadIds.contains(n.id)) return n.copyWith(isRead: true);
        return n;
      }).toList();
      _serverUnreadCount =
          _notifications.where((notification) => !notification.isRead).length;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void handleNotificationNew(Map<String, dynamic> payload) {
    final notification = NotificationModel.fromJson(payload);
    if (notification.id.isEmpty) return;
    _notifications.removeWhere((item) => item.id == notification.id);
    _notifications.insert(0, notification);
    _locallyReadIds.remove(notification.id);
    notifyListeners();
  }

  void handleNotificationRead(Map<String, dynamic> payload) {
    final notificationId = payload['notificationId']?.toString();
    if (payload['all'] == true) {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      _locallyReadIds
          .addAll(_notifications.map((notification) => notification.id));
    } else if (notificationId != null) {
      _locallyReadIds.add(notificationId);
      _notifications = _notifications
          .map((notification) => notification.id == notificationId
              ? notification.copyWith(isRead: true)
              : notification)
          .toList();
    }
    _setUnreadCount(payload['unreadCount']);
    notifyListeners();
  }

  void handleNotificationDeleted(Map<String, dynamic> payload) {
    final notificationId = payload['notificationId']?.toString();
    if (notificationId != null) {
      _notifications
          .removeWhere((notification) => notification.id == notificationId);
      _locallyReadIds.remove(notificationId);
    }
    _setUnreadCount(payload['unreadCount']);
    notifyListeners();
  }

  void handleUnreadCountUpdated(Map<String, dynamic> payload) {
    _setUnreadCount(payload['unreadCount']);
    notifyListeners();
  }

  void _setUnreadCount(dynamic value) {
    final count = int.tryParse(value?.toString() ?? '');
    if (count != null) _serverUnreadCount = count;
  }

  Future<void> markAsRead(String id) async {
    _locallyReadIds.add(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
      try {
        await _repository.markAsRead(id);
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      _locallyReadIds.add(n.id);
    }
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _repository.markAllAsRead();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    _locallyReadIds.remove(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await _repository.deleteNotification(id);
    } catch (_) {}
  }

  Future<void> deleteAllNotifications() async {
    _locallyReadIds.clear();
    _notifications.clear();
    notifyListeners();
    try {
      await _repository.deleteAllNotifications();
    } catch (_) {}
  }
}
