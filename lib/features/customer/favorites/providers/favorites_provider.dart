import 'package:flutter/foundation.dart';

import 'package:bookease/features/customer/favorites/data/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;

  List<String> _favorites = [];
  bool _hasUnreadFavorites = false;
  String? _userId;

  FavoritesProvider(this._repository);

  List<String> get favorites => _favorites;
  bool get hasUnreadFavorites => _hasUnreadFavorites;

  Future<void> attachUser({required String? userId, required bool isAuthenticated}) async {
    if (!isAuthenticated || userId == null || userId.isEmpty) {
      _favorites = [];
      _hasUnreadFavorites = false;
      _userId = null;
      notifyListeners();
      return;
    }

    if (_userId != userId) {
      _userId = userId;
      await loadFavorites();
    }
  }

  Future<void> loadFavorites() async {
    try {
      _favorites = await _repository.getFavoriteIds();
      notifyListeners();
    } catch (_) {
      _favorites = [];
      notifyListeners();
    }
  }

  bool isFavorite(String serviceId) => _favorites.contains(serviceId);

  void markFavoritesAsViewed() {
    if (_hasUnreadFavorites) {
      _hasUnreadFavorites = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String serviceId) async {
    final wasFavorite = _favorites.contains(serviceId);
    if (wasFavorite) {
      _favorites = _favorites.where((id) => id != serviceId).toList();
    } else {
      _favorites = [..._favorites, serviceId];
      _hasUnreadFavorites = true;
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(serviceId);
      } else {
        await _repository.addFavorite(serviceId);
      }
    } catch (_) {
      // Revert on failure by reloading from backend source of truth
      await loadFavorites();
    }
  }
}
