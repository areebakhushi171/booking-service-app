import 'package:bookease/features/customer/services/data/datasources/service_remote_datasource.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';
import 'package:bookease/features/customer/services/data/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource _remoteSource;

  ServiceRepositoryImpl(this._remoteSource);

  @override
  Future<List<ServiceModel>> fetchServices() async {
    return await _remoteSource.fetchServices();
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    return await _remoteSource.getServiceById(id);
  }

  @override
  Future<List<ServiceModel>> fetchProviderServices(String providerId) async {
    return await _remoteSource.fetchProviderServices(providerId);
  }

  @override
  Future<void> saveProviderService(ServiceModel service) async {
    if (service.id.isEmpty || service.id.startsWith('SRV-')) {
      await _remoteSource.createService(service);
    } else {
      await _remoteSource.updateService(service);
    }
  }

  @override
  Future<void> deleteProviderService(String serviceId) async {
    await _remoteSource.deleteService(serviceId);
  }
}
