import 'package:flutter_test/flutter_test.dart';
import 'package:bookease/features/chat/data/models/chat_model.dart';
import 'package:bookease/features/chat/data/repositories/chat_repository.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';
import 'package:bookease/features/customer/bookings/data/models/booking_model.dart';
import 'package:bookease/features/customer/bookings/data/repositories/booking_repository.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/core/services/notification_service.dart';
import 'package:bookease/features/notifications/data/models/notification_model.dart';
import 'package:bookease/features/notifications/data/repositories/notification_repository.dart';
import 'package:bookease/features/notifications/providers/notification_provider.dart';

class _ChatRepository implements ChatRepository {
  @override
  Future<List<ConversationModel>> fetchConversations() async => [];

  @override
  Future<ConversationModel> createConversation({
    required String propertyId,
    String? participantId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<MessageModel>> fetchMessages(String conversationId) async => [];

  @override
  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> markConversationRead(String conversationId) async {}
}

class _BookingRepository implements BookingRepository {
  @override
  Future<List<BookingModel>> getBookings({bool isProvider = false}) async => [];

  @override
  Future<ProviderDashboardSummary> getProviderDashboardSummary() async =>
      const ProviderDashboardSummary(
        totalEarnings: 0,
        completedBookingsCount: 0,
        pendingBookingsCount: 0,
        acceptedBookingsCount: 0,
        totalBookingsCount: 0,
      );

  @override
  Future<BookingModel> createBooking(BookingModel booking) async => booking;

  @override
  Future<void> updateBooking(BookingModel booking) async {}

  @override
  Future<BookingModel> acceptBooking(String id) async =>
      throw UnimplementedError();

  @override
  Future<BookingModel> rejectBooking(String id) async =>
      throw UnimplementedError();

  @override
  Future<BookingModel> updateStatus(String id, String status) async =>
      throw UnimplementedError();
}

class _NotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationModel>> fetchNotifications() async => [];

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}

  @override
  Future<void> deleteNotification(String id) async {}

  @override
  Future<void> deleteAllNotifications() async {}
}

void main() {
  test('booking prices use persisted amount fields and preserve missing values',
      () {
    final booking = BookingModel.fromJson({
      'id': 'booking-price',
      'serviceId': 'service-1',
      'servicePrice': null,
      'amount': '2500.00',
      'service': {'price': '9999.00'},
      'createdAt': '2026-11-25T10:00:00.000Z',
    });
    final historicalBooking = BookingModel.fromJson({
      'id': 'booking-historical',
      'serviceId': 'service-1',
      'service': {'price': '9999.00'},
      'createdAt': '2026-11-25T10:00:00.000Z',
    });

    expect(booking.servicePrice, 2500);
    expect(historicalBooking.servicePrice, 9999);
    expect(historicalBooking.formattedServicePrice, 'Rs 9999');
    expect(
      ProviderDashboardSummary.fromJson({
        'totalEarnings': '4000.00',
        'completedBookingsCount': 2,
        'pendingBookingsCount': 1,
        'acceptedBookingsCount': 3,
        'totalBookingsCount': 6,
      }).totalEarnings,
      4000,
    );
  });

  test('message events upsert by ID and apply read receipts', () async {
    final provider = ChatProvider(_ChatRepository());
    await Future<void>.delayed(Duration.zero);

    final message = {
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'senderId': 'provider-1',
      'content': 'Hello',
      'createdAt': '2026-11-25T10:00:00.000Z',
      'readAt': null,
    };
    final event = {
      'conversationId': 'conversation-1',
      'message': message,
      'unreadCount': 1,
      'globalUnreadCount': 1,
    };

    provider.handleMessageNew(event);
    provider.handleMessageNew(event);

    expect(provider.messagesFor('conversation-1'), hasLength(1));
    expect(provider.unreadCount, 1);
    expect(provider.messagesFor('conversation-1').single.isRead, isFalse);

    provider.handleMessageRead({
      'conversationId': 'conversation-1',
      'readerId': 'customer-1',
      'messageIds': ['message-1'],
      'readAt': '2026-11-25T10:01:00.000Z',
    });

    expect(provider.messagesFor('conversation-1').single.isRead, isTrue);
    await Future<void>.delayed(Duration.zero);
    provider.dispose();
  });

  test('booking events update persisted status without duplicate records',
      () async {
    final provider = BookingProvider(
      _BookingRepository(),
      NotificationService(),
    );
    provider.attachUser(userId: 'provider-1', isProvider: true);
    await Future<void>.delayed(Duration.zero);

    final event = {
      'event': 'booking:rejected',
      'booking': {
        'id': 'booking-1',
        'serviceId': 'service-1',
        'customerId': 'customer-1',
        'startDate': '2026-12-01T10:00:00.000Z',
        'endDate': '2026-12-01T11:00:00.000Z',
        'status': 'REJECTED',
        'createdAt': '2026-11-25T10:00:00.000Z',
        'customer': {'id': 'customer-1', 'name': 'Customer'},
        'service': {
          'id': 'service-1',
          'name': 'Service',
          'providerId': 'provider-1',
          'provider': {'id': 'provider-1', 'name': 'Provider'},
        },
      },
    };

    provider.handleRealtimeBooking(event);
    provider.handleRealtimeBooking(event);

    expect(provider.providerBookings, hasLength(1));
    expect(provider.providerBookings.single.id, 'booking-1');
    expect(provider.providerBookings.single.status, BookingStatus.rejected);
    await Future<void>.delayed(Duration.zero);
    provider.dispose();
  });

  test('notification events deduplicate and apply unread counts', () {
    final provider = NotificationProvider(
      _NotificationRepository(),
      loadOnStart: false,
    );
    const notification = {
      'id': 'notification-1',
      'type': 'MESSAGE',
      'title': 'New Message',
      'message': 'You have a new message.',
      'data': {'conversationId': 'conversation-1'},
      'createdAt': '2026-11-25T10:00:00.000Z',
      'readAt': null,
    };

    provider.handleNotificationNew(notification);
    provider.handleNotificationNew(notification);
    provider.handleUnreadCountUpdated({'unreadCount': 1});

    expect(provider.notifications, hasLength(1));
    expect(provider.notifications.single.data?['conversationId'],
        'conversation-1');
    expect(provider.unreadCount, 1);

    provider.handleNotificationRead({
      'notificationId': 'notification-1',
      'unreadCount': 0,
    });
    expect(provider.notifications.single.isRead, isTrue);
    expect(provider.unreadCount, 0);
    provider.dispose();
  });
}
