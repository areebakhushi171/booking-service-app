import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:bookease/core/services/notification_service.dart';
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

  final authSource = AuthRemoteDataSource(apiClient);
  final authRepository = AuthRepositoryImpl(authSource, tokenStorage, storage);
  final settingsRepository = SettingsRepository(storage);

  final serviceRemote = ServiceRemoteDataSource(apiClient);
  final serviceRepository = ServiceRepositoryImpl(serviceRemote);

  final bookingRemote = BookingRemoteDataSource(apiClient);
  final bookingRepository = BookingRepositoryImpl(bookingRemote);

  final favoritesRemote = FavoritesRemoteDataSource(apiClient);
  final favoritesRepository = FavoritesRepositoryImpl(favoritesRemote);

  final notificationRepository = NotificationRepository(NotificationRemoteDataSource(apiClient));
  final chatRepository = ChatRepository(ChatRemoteDataSource(apiClient));

  return [
    ChangeNotifierProvider(create: (_) => ThemeProvider(settingsRepository)),
    ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
    ChangeNotifierProvider(create: (_) => ServiceProvider(serviceRepository)),
    ChangeNotifierProvider(create: (_) => FavoritesProvider(favoritesRepository)),
    ChangeNotifierProvider(create: (_) => NotificationProvider(notificationRepository)),
    ChangeNotifierProvider(create: (_) => ChatProvider(chatRepository)),
    ChangeNotifierProvider(create: (_) => ProviderServicesProvider(serviceRepository)),
    ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
      create: (_) => BookingProvider(bookingRepository, notificationService),
      update: (_, auth, bookings) => bookings!
        ..attachUser(
          userId: auth.currentUser?.id,
          isProvider: auth.currentUser?.isProvider ?? false,
        ),
    ),
  ];
}
