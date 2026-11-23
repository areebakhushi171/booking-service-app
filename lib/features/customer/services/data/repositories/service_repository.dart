import 'package:bookease/features/customer/services/data/models/service_model.dart';

/// Contract for the service catalog using backend REST API.
abstract class ServiceRepository {
  Future<List<ServiceModel>> fetchServices();
  Future<ServiceModel> getServiceById(String id);

  // --- Provider panel ---
  Future<List<ServiceModel>> fetchProviderServices(String providerId);
  Future<void> saveProviderService(ServiceModel service);
  Future<void> deleteProviderService(String serviceId);
}
