import 'package:flutter/foundation.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/data/repositories/service_repository.dart';

enum ServiceSort { priceAsc, priceDesc, durationAsc, nameAsc }

class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  List<ServiceModel> _services = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedCategory;
  String _searchQuery = '';
  ServiceSort _currentSort = ServiceSort.priceAsc;
  double? _minPrice;
  double? _maxPrice;
  int? _maxDurationMinutes;

  ServiceProvider(this._repository) {
    loadServices();
  }

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  ServiceSort get currentSort => _currentSort;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  int? get maxDurationMinutes => _maxDurationMinutes;

  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _searchQuery.isNotEmpty ||
      _minPrice != null ||
      _maxPrice != null ||
      _maxDurationMinutes != null ||
      _currentSort != ServiceSort.priceAsc;

  List<ServiceModel> get popularServices =>
      _services.where((s) => s.isPopular).toList();

  List<ServiceModel> get providerServices =>
      _services.where((s) => s.providerId != null).toList();

  List<ServiceModel> get filteredServices {
    List<ServiceModel> list = List.from(_services);

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      list = list.where((s) => s.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q))
          .toList();
    }

    if (_minPrice != null) {
      list = list.where((s) => s.price >= _minPrice!).toList();
    }

    if (_maxPrice != null) {
      list = list.where((s) => s.price <= _maxPrice!).toList();
    }

    if (_maxDurationMinutes != null) {
      list = list.where((s) => s.durationMinutes <= _maxDurationMinutes!).toList();
    }

    switch (_currentSort) {
      case ServiceSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ServiceSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ServiceSort.durationAsc:
        list.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
        break;
      case ServiceSort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return list;
  }

  Future<void> loadServices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _services = await _repository.fetchServices();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    if (_selectedCategory == categoryId) {
      _selectedCategory = null;
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

  void applyFilterSheet({
    String? category,
    ServiceSort? sort,
    double? minPrice,
    double? maxPrice,
    int? maxDuration,
  }) {
    _selectedCategory = category;
    if (sort != null) _currentSort = sort;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _maxDurationMinutes = maxDuration;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _currentSort = ServiceSort.priceAsc;
    _minPrice = null;
    _maxPrice = null;
    _maxDurationMinutes = null;
    notifyListeners();
  }
}