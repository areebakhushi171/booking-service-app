import 'package:flutter/foundation.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/data/repositories/service_repository.dart';

enum ServiceSort { priceAsc, priceDesc, durationAsc }

class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  List<ServiceModel> _services = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedCategory;
  String _searchQuery = '';
  ServiceSort _currentSort = ServiceSort.priceAsc;

  ServiceProvider(this._repository) {
    loadServices();
  }

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  ServiceSort get currentSort => _currentSort;

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
}
