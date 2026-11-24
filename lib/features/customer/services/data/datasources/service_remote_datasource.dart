import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

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

  Future<ServiceModel> createServiceMultipart(
    ServiceModel service,
    File? mainImageFile,
    List<File> galleryFiles,
  ) async {
    final map = <String, dynamic>{
      'name': service.name,
      'title': service.name,
      'category': service.category,
      'description': service.description,
      'price': service.price.toString(),
      'duration': service.durationMinutes.toString(),
      'durationMinutes': service.durationMinutes.toString(),
      'country': service.country,
      'city': service.city,
      'isActive': service.isActive.toString(),
      if (service.features.isNotEmpty) ...{
        'features': service.features,
        'featuresJson': jsonEncode(service.features),
      },
    };

    if (mainImageFile != null) {
      final fileName = mainImageFile.path.split('/').last;
      map['mainImage'] = await MultipartFile.fromFile(mainImageFile.path, filename: fileName);
    } else if (service.imageUrl.isNotEmpty) {
      map['imageUrl'] = service.imageUrl;
    }

    if (galleryFiles.isNotEmpty) {
      final multipartGallery = <MultipartFile>[];
      for (final f in galleryFiles) {
        final fileName = f.path.split('/').last;
        multipartGallery.add(await MultipartFile.fromFile(f.path, filename: fileName));
      }
      map['galleryImages'] = multipartGallery;
    }

    final formData = FormData.fromMap(map);
    final res = await _client.post(ApiEndpoints.properties, body: formData);
    return _parseSingle(res.data);
  }

  Future<ServiceModel> updateServiceMultipart(
    ServiceModel service,
    File? mainImageFile,
    List<File> galleryFiles,
    List<String> existingGalleryUrls,
  ) async {
    final map = <String, dynamic>{
      'name': service.name,
      'title': service.name,
      'category': service.category,
      'description': service.description,
      'price': service.price.toString(),
      'duration': service.durationMinutes.toString(),
      'durationMinutes': service.durationMinutes.toString(),
      'country': service.country,
      'city': service.city,
      'isActive': service.isActive.toString(),
      if (service.features.isNotEmpty) ...{
        'features': service.features,
        'featuresJson': jsonEncode(service.features),
      },
      if (existingGalleryUrls.isNotEmpty) 'existingGalleryImages': existingGalleryUrls,
    };

    if (mainImageFile != null) {
      final fileName = mainImageFile.path.split('/').last;
      map['mainImage'] = await MultipartFile.fromFile(mainImageFile.path, filename: fileName);
    } else if (service.imageUrl.isNotEmpty) {
      map['imageUrl'] = service.imageUrl;
    }

    if (galleryFiles.isNotEmpty) {
      final multipartGallery = <MultipartFile>[];
      for (final f in galleryFiles) {
        final fileName = f.path.split('/').last;
        multipartGallery.add(await MultipartFile.fromFile(f.path, filename: fileName));
      }
      map['galleryImages'] = multipartGallery;
    }

    final formData = FormData.fromMap(map);
    final res = await _client.patch(ApiEndpoints.propertyById(service.id), body: formData);
    return _parseSingle(res.data);
  }

  Future<void> deleteService(String id) async {
    await _client.delete(ApiEndpoints.propertyById(id));
  }

  Future<void> deleteServiceImages(String propertyId, List<String> imageUrls) async {
    await _client.delete('${ApiEndpoints.propertyById(propertyId)}/images', body: {'imageUrls': imageUrls});
  }
}
