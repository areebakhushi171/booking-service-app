import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookease/core/network/api_client.dart';
import 'package:bookease/core/storage/local_storage_service.dart';
import 'package:bookease/core/storage/token_storage.dart';
import 'package:bookease/features/customer/services/data/datasources/service_remote_datasource.dart';
import 'package:bookease/features/customer/services/data/models/service_model.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final List<String> multipartBodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = await requestStream!.toList();
    multipartBodies.add(
      latin1.decode(chunks.expand((chunk) => chunk).toList()),
    );
    return ResponseBody.fromString(
      jsonEncode({
        'property': {
          'id': 'service-id',
          'name': 'Service',
          'category': 'cleaning',
          'description': 'Service description',
          'price': 2500,
          'duration': 60,
        }
      }),
      200,
      headers: {
        'content-type': ['application/json']
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ServiceModel _service({String id = ''}) => ServiceModel(
      id: id,
      name: 'Service',
      category: 'cleaning',
      description: 'Service description',
      price: 2500,
      durationMinutes: 60,
      imageUrl: '',
    );

Set<String> _binaryFieldNames(String body) => RegExp(
      r'content-disposition: form-data; name="([^"]+)"; filename=',
      caseSensitive: false,
    ).allMatches(body).map((match) => match.group(1)!).toSet();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('service create and edit send only Multer image file fields', () async {
    SharedPreferences.setMockInitialValues({});
    final tempDirectory = await Directory.systemTemp.createTemp(
      'bookease-multipart-test-',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    Future<File> image(String name) async {
      final file = File('${tempDirectory.path}/$name.png');
      await file.writeAsBytes(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      );
      return file;
    }

    final cover = await image('cover');
    final gallery = [
      for (var index = 0; index < 5; index++) await image('gallery-$index'),
    ];
    final adapter = _CaptureAdapter();
    final dio = Dio(BaseOptions(
      baseUrl: 'https://bookease.test/api',
      responseType: ResponseType.json,
    ))
      ..httpClientAdapter = adapter;
    final storage = LocalStorageService(
      await SharedPreferences.getInstance(),
    );
    final source = ServiceRemoteDataSource(
      ApiClient(TokenStorage(storage), customDio: dio),
    );

    await source.createServiceMultipart(_service(), cover, const []);
    expect(_binaryFieldNames(adapter.multipartBodies.last), {'mainImage'});

    await source.createServiceMultipart(_service(), null, [gallery.first]);
    expect(_binaryFieldNames(adapter.multipartBodies.last), {'galleryImages'});

    await source.createServiceMultipart(_service(), cover, gallery);
    expect(
      _binaryFieldNames(adapter.multipartBodies.last),
      {'mainImage', 'galleryImages'},
    );
    expect(
      RegExp(r'filename=', caseSensitive: false)
          .allMatches(adapter.multipartBodies.last)
          .length,
      6,
    );

    await source.updateServiceMultipart(
        _service(id: 'service-id'), cover, [gallery.first], const []);
    expect(
      _binaryFieldNames(adapter.multipartBodies.last),
      {'mainImage', 'galleryImages'},
    );
    expect(
      _binaryFieldNames(adapter.multipartBodies.last).contains('image'),
      isFalse,
    );
    expect(
      _binaryFieldNames(adapter.multipartBodies.last).contains('gallery'),
      isFalse,
    );
    dio.close(force: true);
  });
}
