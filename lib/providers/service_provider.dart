import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum ServiceSort { ratingDesc, priceAsc, priceDesc, durationAsc }

class ServiceProvider extends ChangeNotifier {
  final IServiceRepository _apiService;
  final StorageService _storageService;

  List<ServiceModel> _services = [];
  List<String> _favorites = [];
  bool _hasUnreadFavorites = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOfflineMode = false;

  String? _selectedCategory;
  String _searchQuery = '';
  ServiceSort _currentSort = ServiceSort.ratingDesc;

  ServiceProvider(this._apiService, this._storageService) {
    _favorites = _storageService.getFavorites();
    loadServices();
  }

  List<ServiceModel> get services => _services;
  List<String> get favorites => _favorites;
  bool get hasUnreadFavorites => _hasUnreadFavorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  ServiceSort get currentSort => _currentSort;

  List<ServiceModel> get popularServices =>
      _services.where((s) => s.isPopular).toList();

  List<ServiceModel> get topRatedServices =>
      _services.where((s) => s.isTopRated).toList();

  List<ServiceModel> get filteredServices {
    List<ServiceModel> list = List.from(_services);

    // 1. Category Filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      list = list.where((s) => s.category == _selectedCategory).toList();
    }

    // 2. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q))
          .toList();
    }

    // 3. Sorting
    switch (_currentSort) {
      case ServiceSort.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ServiceSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ServiceSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ServiceSort.durationAsc:
        list.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
    }

    return list;
  }

  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _apiService.fetchServices();
      _services = fetched;
      _isOfflineMode = false;
      await _storageService.cacheServices(fetched);
    } catch (e) {
      _errorMessage = e.toString();
      // Try local cache for offline resiliency
      final cached = _storageService.getCachedServices();
      if (cached.isNotEmpty) {
        _services = cached;
        _isOfflineMode = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    if (_selectedCategory == categoryId) {
      _selectedCategory = null; // Toggle off if clicked again
    } else {
      _selectedCategory = categoryId;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(ServiceSort sort) {
    _currentSort = sort;
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
    if (_favorites.contains(serviceId)) {
      _favorites.remove(serviceId);
    } else {
      _favorites.add(serviceId);
      _hasUnreadFavorites = true;
    }
    notifyListeners();
    await _storageService.saveFavorites(_favorites);
  }

  List<ServiceModel> get favoriteServices =>
      _services.where((s) => _favorites.contains(s.id)).toList();
}
