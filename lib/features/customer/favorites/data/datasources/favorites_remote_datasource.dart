import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/network/api_endpoints.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

class FavoritesRemoteDataSource {
  final ApiClient _client;
  FavoritesRemoteDataSource(this._client);

  Future<List<ServiceModel>> fetchFavoriteServices() async {
    final res = await _client.get(ApiEndpoints.favorites);
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['favorites'] ?? data['data'] ?? []) as List : []);

    return list.whereType<Map>().map((favorite) {
      final service = favorite['service'];
      if (service is Map) {
        return ServiceModel.fromJson(Map<String, dynamic>.from(service));
      }
      // Compatibility with older API payloads that return service fields flat.
      return ServiceModel.fromJson(Map<String, dynamic>.from(favorite));
    }).where((service) => service.id.isNotEmpty).toList();
  }

  Future<void> addFavorite(String propertyId) async {
    await _client.post(ApiEndpoints.favoriteByPropertyId(propertyId));
  }

  Future<void> removeFavorite(String propertyId) async {
    await _client.delete(ApiEndpoints.favoriteByPropertyId(propertyId));
  }

  Future<bool> checkFavorite(String propertyId) async {
    try {
      final res = await _client.get(ApiEndpoints.checkFavorite(propertyId));
      if (res.data is Map) {
        return (res.data['isFavorite'] ?? res.data['favorited'] ?? false) as bool;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
