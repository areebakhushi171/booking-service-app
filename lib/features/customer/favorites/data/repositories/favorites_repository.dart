import 'package:bookease/features/customer/services/data/models/service_model.dart';

/// Contract for favorite services. The backend remains the source of truth.
abstract class FavoritesRepository {
  Future<List<ServiceModel>> getFavoriteServices();
  Future<void> addFavorite(String serviceId);
  Future<void> removeFavorite(String serviceId);
}
