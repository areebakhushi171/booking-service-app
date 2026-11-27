import 'dart:async';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:bookease/core/services/notification_service.dart';
import 'package:bookease/core/services/socket_service.dart';
import 'package:bookease/core/storage/local_storage_service.dart';
import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/storage/token_storage.dart';
import 'package:bookease/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bookease/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bookease/features/auth/providers/auth_provider.dart';
import 'package:bookease/features/customer/bookings/data/datasources/booking_remote_datasource.dart';
import 'package:bookease/features/customer/bookings/data/repositories/booking_repository_impl.dart';
import 'package:bookease/features/customer/bookings/providers/booking_provider.dart';
import 'package:bookease/features/customer/favorites/data/datasources/favorites_remote_datasource.dart';
import 'package:bookease/features/customer/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:bookease/features/customer/favorites/providers/favorites_provider.dart';
import 'package:bookease/features/customer/services/data/datasources/service_remote_datasource.dart';
import 'package:bookease/features/customer/services/data/repositories/service_repository_impl.dart';
import 'package:bookease/features/customer/services/providers/service_provider.dart';
import 'package:bookease/features/profile/data/repositories/settings_repository.dart';
import 'package:bookease/features/provider/providers/provider_services_provider.dart';
import 'package:bookease/features/profile/providers/theme_provider.dart';
import 'package:bookease/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:bookease/features/notifications/data/repositories/notification_repository.dart';
import 'package:bookease/features/notifications/providers/notification_provider.dart';
import 'package:bookease/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:bookease/features/chat/data/repositories/chat_repository.dart';
import 'package:bookease/features/chat/providers/chat_provider.dart';

Future<List<SingleChildWidget>> buildAppProviders() async {
  final storage = await LocalStorageService.create();

  final notificationService = NotificationService();
  await notificationService.init();

  final tokenStorage = TokenStorage(storage);
  final apiClient = ApiClient(tokenStorage);

  final socketService = SocketService(tokenStorage);

  final authSource = AuthRemoteDataSource(apiClient);
  final authRepository = AuthRepositoryImpl(authSource, tokenStorage, storage);
  final settingsRepository = SettingsRepository(storage);

  final serviceRemote = ServiceRemoteDataSource(apiClient);
  final serviceRepository = ServiceRepositoryImpl(serviceRemote);

  final bookingRemote = BookingRemoteDataSource(apiClient);
  final bookingRepository = BookingRepositoryImpl(bookingRemote);

  final favoritesRemote = FavoritesRemoteDataSource(apiClient);
  final favoritesRepository = FavoritesRepositoryImpl(favoritesRemote);

  final notificationRepository =
      NotificationRepository(NotificationRemoteDataSource(apiClient));
  final notificationProvider = NotificationProvider(
    notificationRepository,
    loadOnStart: false,
  );

  final chatRepository = ChatRepository(ChatRemoteDataSource(apiClient));
  final chatProvider = ChatProvider(chatRepository, socketService);

  final bookingProvider =
      BookingProvider(bookingRepository, notificationService);
  final serviceProvider = ServiceProvider(serviceRepository);
  final providerServicesProvider = ProviderServicesProvider(serviceRepository);
  final favoritesProvider = FavoritesProvider(favoritesRepository);
  final authProvider = AuthProvider(authRepository, socketService);

  var recoveryRunning = false;
  var recoveryRequested = false;
  void recoverAfterSocketConnect() {
    recoveryRequested = true;
    if (recoveryRunning) return;

    recoveryRunning = true;
    unawaited(() async {
      try {
        while (recoveryRequested) {
          recoveryRequested = false;
          final tasks = <Future<void>>[
            chatProvider.handleSocketConnected(),
            bookingProvider.loadBookings(),
            notificationProvider.loadNotifications(),
            serviceProvider.loadServices(),
            favoritesProvider.loadFavorites(),
          ];
          final user = authProvider.currentUser;
          if (user?.isProvider == true) {
            tasks
              ..add(providerServicesProvider.load(user!.id))
              ..add(bookingProvider.loadProviderDashboardSummary());
          }
          await Future.wait(tasks);
        }
      } finally {
        recoveryRunning = false;
      }
    }());
  }

  socketService.onConnected = recoverAfterSocketConnect;
  socketService.onDisconnected = chatProvider.handleSocketDisconnected;
  socketService.onMessageNew = chatProvider.handleMessageNew;
  socketService.onMessageRead = chatProvider.handleMessageRead;
  socketService.onChatUnreadCountUpdated =
      chatProvider.handleUnreadCountUpdated;
  socketService.onConversationUpdated = chatProvider.handleConversationUpdated;
  socketService.onTyping =
      (payload) => chatProvider.handleTyping(payload, isTyping: true);
  socketService.onStopTyping =
      (payload) => chatProvider.handleTyping(payload, isTyping: false);
  socketService.onBookingEvent = bookingProvider.handleRealtimeBooking;
  socketService.onNotificationNew = notificationProvider.handleNotificationNew;
  socketService.onNotificationRead =
      notificationProvider.handleNotificationRead;
  socketService.onNotificationDeleted =
      notificationProvider.handleNotificationDeleted;
  socketService.onNotificationUnreadCountUpdated =
      notificationProvider.handleUnreadCountUpdated;
  socketService.onPresenceEvent = chatProvider.handlePresence;
  socketService.onServiceEvent = (_) {
    unawaited(serviceProvider.loadServices());
    unawaited(favoritesProvider.loadFavorites());
    final user = authProvider.currentUser;
    if (user?.isProvider == true) {
      unawaited(providerServicesProvider.load(user!.id));
    }
  };
  socketService.onFavoriteEvent = (_) {
    unawaited(favoritesProvider.loadFavorites());
  };

  return [
    Provider<SocketService>.value(value: socketService),
    ChangeNotifierProvider(create: (_) => ThemeProvider(settingsRepository)),
    ChangeNotifierProvider.value(value: authProvider),
    ChangeNotifierProvider.value(value: serviceProvider),
    ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
      create: (_) => favoritesProvider,
      update: (_, auth, favorites) => favorites!
        ..attachUser(
          userId: auth.currentUser?.id,
          isAuthenticated: auth.isAuthenticated,
        ),
    ),
    ChangeNotifierProvider.value(value: notificationProvider),
    ChangeNotifierProvider.value(value: chatProvider),
    ChangeNotifierProvider.value(value: providerServicesProvider),
    ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
      create: (_) => bookingProvider,
      update: (_, auth, bookings) => bookings!
        ..attachUser(
          userId: auth.currentUser?.id,
          isProvider: auth.currentUser?.isProvider ?? false,
        ),
    ),
  ];
}
