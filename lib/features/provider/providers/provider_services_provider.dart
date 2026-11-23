import 'package:flutter/foundation.dart';

import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/data/repositories/service_repository.dart';

/// State for the provider panel's "My Services" tab.
/// Talks only to [ServiceRepository] (local today, REST later).
class ProviderServicesProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  ProviderServicesProvider(this._repository);

  String? _providerId;
  List<ServiceModel> _services = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get activeCount => _services.where((s) => s.isActive).length;

  Future<void> load(String providerId) async {
    _providerId = providerId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _services = await _repository.fetchProviderServices(providerId);
    } catch (e) {
      _errorMessage = 'Could not load your services.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(ServiceModel service) async {
    await _repository.saveProviderService(service);
    await _reload();
  }

  Future<void> delete(String serviceId) async {
    await _repository.deleteProviderService(serviceId);
    await _reload();
  }

  Future<void> setActive(ServiceModel service, bool active) async {
    await _repository.saveProviderService(service.copyWith(isActive: active));
    await _reload();
  }

  Future<void> _reload() async {
    final id = _providerId;
    if (id == null) return;
    _services = await _repository.fetchProviderServices(id);
    notifyListeners();
  }

  /// Unique id for a new listing.
  String newServiceId() => 'svc-${DateTime.now().microsecondsSinceEpoch}';
}
