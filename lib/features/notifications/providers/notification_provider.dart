import 'package:flutter/foundation.dart';
import 'package:bookease/features/notifications/data/models/notification_model.dart';
import 'package:bookease/features/notifications/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  List<NotificationModel> _notifications = [];
  final Set<String> _locallyReadIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  NotificationProvider(this._repository) {
    loadNotifications();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

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
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
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
}
