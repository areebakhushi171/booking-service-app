import 'package:flutter/foundation.dart';

import 'package:bookease/features/customer/favorites/data/repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;

  List<String> _favorites = [];
  bool _hasUnreadFavorites = false;

  FavoritesProvider(this._repository) {
    _load();
  }

  List<String> get favorites => _favorites;
  bool get hasUnreadFavorites => _hasUnreadFavorites;

  Future<void> _load() async {
    _favorites = await _repository.getFavoriteIds();
    notifyListeners();
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
      // Revert on failure
      await _load();
    }
  }
}
