import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/network/api_endpoints.dart';

class FavoritesRemoteDataSource {
  final ApiClient _client;
  FavoritesRemoteDataSource(this._client);

  Future<List<String>> fetchFavoriteIds() async {
    final res = await _client.get(ApiEndpoints.favorites);
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? (data['favorites'] ?? data['data'] ?? []) as List : []);
    return list.map((e) {
      if (e is String) return e;
      if (e is Map) return (e['propertyId'] ?? e['id'] ?? '').toString();
      return e.toString();
    }).where((id) => id.isNotEmpty).toList();
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
