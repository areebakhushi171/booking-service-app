/// Contract for favorite services.
/// Future REST mapping: GET /favorites, POST /favorites/:id, DELETE /favorites/:id
abstract class FavoritesRepository {
  Future<List<String>> getFavoriteIds();
  Future<void> addFavorite(String serviceId);
  Future<void> removeFavorite(String serviceId);
}
