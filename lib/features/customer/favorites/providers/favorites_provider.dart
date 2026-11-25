import 'package:flutter/foundation.dart';

import 'package:bookease/features/customer/favorites/data/repositories/favorites_repository.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;

  List<String> _favorites = [];
  List<ServiceModel> _favoriteServices = [];
  bool _hasUnreadFavorites = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;

  FavoritesProvider(this._repository);

  List<String> get favorites => _favorites;
  List<ServiceModel> get favoriteServices => _favoriteServices;
  bool get hasUnreadFavorites => _hasUnreadFavorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> attachUser({required String? userId, required bool isAuthenticated}) async {
    if (!isAuthenticated || userId == null || userId.isEmpty) {
      _favorites = [];
      _favoriteServices = [];
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _favoriteServices = await _repository.getFavoriteServices();
      _favorites = _favoriteServices.map((service) => service.id).toSet().toList();
    } catch (error) {
      // Keep the last known list on network errors; an error must not look
      // like the customer has no saved favorites.
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
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
    _errorMessage = null;
    try {
      // Persist first. Only update the UI after the backend confirms success.
      if (wasFavorite) {
        await _repository.removeFavorite(serviceId);
        _favorites = _favorites.where((id) => id != serviceId).toList();
        _favoriteServices = _favoriteServices.where((service) => service.id != serviceId).toList();
      } else {
        await _repository.addFavorite(serviceId);
        _favorites = [..._favorites, serviceId];
        _hasUnreadFavorites = true;
      }
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      await loadFavorites();
    }
  }
}
