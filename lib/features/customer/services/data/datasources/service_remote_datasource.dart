import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/network/api_endpoints.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

class ServiceRemoteDataSource {
  final ApiClient _client;
  ServiceRemoteDataSource(this._client);

  List<ServiceModel> _parseList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['properties'] ?? data['data'] ?? data['services'] ?? []) as List : []);
    return list.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  ServiceModel _parseSingle(dynamic data) {
    final json = data is Map
        ? (data['property'] ?? data['service'] ?? data['data'] ?? data) as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return ServiceModel.fromJson(json);
  }

  Future<List<ServiceModel>> fetchServices({Map<String, String>? query}) async {
    final res = await _client.get(ApiEndpoints.properties, query: query);
    return _parseList(res.data);
  }

  Future<ServiceModel> getServiceById(String id) async {
    final res = await _client.get(ApiEndpoints.propertyById(id));
    return _parseSingle(res.data);
  }

  Future<List<ServiceModel>> fetchOwnerServices() async {
    final res = await _client.get(ApiEndpoints.myProperties);
    return _parseList(res.data);
  }

  Future<List<ServiceModel>> fetchProviderServices(String providerId) async {
    final res = await _client.get(ApiEndpoints.ownerProperties(providerId));
    return _parseList(res.data);
  }

  Future<ServiceModel> createService(ServiceModel service) async {
    final res = await _client.post(ApiEndpoints.properties, body: service.toJson());
    return _parseSingle(res.data);
  }

  Future<ServiceModel> updateService(ServiceModel service) async {
    final res = await _client.patch(ApiEndpoints.propertyById(service.id), body: service.toJson());
    return _parseSingle(res.data);
  }

  Future<void> deleteService(String id) async {
    await _client.delete(ApiEndpoints.propertyById(id));
  }
}
