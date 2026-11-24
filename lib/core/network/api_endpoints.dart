/// All REST paths in one place (relative to NetworkConfig.baseUrl).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/users/me';
  static const String changePassword = '/users/change-password';

  // Image Uploads
  static const String uploadImage = '/upload/image';
  static const String upload = '/upload';
  static const String userAvatar = '/users/me/avatar';
  static const String uploadServiceImage = '/properties/image';

  // Properties (Services in Flutter)
  static const String properties = '/properties';
  static String propertyById(String id) => '/properties/$id';
  static const String myProperties = '/properties/owner/me';
  static String ownerProperties(String ownerId) => '/properties/owner/$ownerId';

  // Bookings
  static const String bookings = '/bookings';
  static const String myBookings = '/bookings/mine';
  static const String bookingHistory = '/bookings/history';
  static const String receivedBookings = '/bookings/received';
  static String bookingById(String id) => '/bookings/$id';
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  static String acceptBooking(String id) => '/bookings/$id/accept';
  static String rejectBooking(String id) => '/bookings/$id/reject';
  static String bookingStatus(String id) => '/bookings/$id/status';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteByPropertyId(String propertyId) => '/favorites/$propertyId';
  static String checkFavorite(String propertyId) => '/favorites/$propertyId/check';

  // Messaging / Conversations
  static const String conversations = '/conversations';
  static const String unreadConversationsCount = '/conversations/unread-count';
  static String conversationMessages(String id) => '/conversations/$id/messages';
  static String readConversation(String id) => '/conversations/$id/read';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadNotifications = '/notifications/unread';
  static const String unreadNotificationsCount = '/notifications/unread-count';
  static const String readAllNotifications = '/notifications/read-all';
  static String notificationById(String id) => '/notifications/$id';
  static String readNotification(String id) => '/notifications/$id/read';
}
