import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:bookease/core/network/api_response.dart';
import 'package:bookease/core/network/network_config.dart';
import 'package:bookease/core/network/network_exceptions.dart';
import 'package:bookease/core/storage/token_storage.dart';

/// Reusable REST client using Dio: base URL, JSON, Bearer token, timeouts and error mapping.
/// Only used when NetworkConfig.useRemoteBackend is true.
class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokens;

  /// Called when the API answers 401 (e.g. to force logout).
  void Function()? onUnauthorized;

  ApiClient(this._tokens, {Dio? customDio}) {
    if (customDio != null) {
      _dio = customDio;
    } else {
      _dio = Dio(
        BaseOptions(
          baseUrl: _normalizeBaseUrl(NetworkConfig.baseUrl),
          connectTimeout: NetworkConfig.connectTimeout,
          receiveTimeout: NetworkConfig.receiveTimeout,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      _setupInterceptors();
    }
  }

  Dio get dio => _dio;

  static String _normalizeBaseUrl(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('🌐 [API REQ] ${options.method} ${options.uri}');
            debugPrint('⏱️ [TIMESTAMP] ${DateTime.now()}');
            if (options.data != null) {
              debugPrint('📦 [REQ BODY] ${_sanitizeData(options.data)}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('📥 [API RES] ${response.requestOptions.method} ${response.requestOptions.uri}');
            debugPrint('🔢 [STATUS] ${response.statusCode}');
            if (response.data != null) {
              debugPrint('📄 [RES BODY] ${_sanitizeData(response.data)}');
            }
          }
          return handler.next(response);
        },
        onError: (DioException err, handler) {
          if (kDebugMode) {
            debugPrint('❌ [API ERROR] ${err.requestOptions.method} ${err.requestOptions.uri} - ${err.type}: ${err.message}');
            if (err.response?.data != null) {
              debugPrint('📄 [ERROR RES] ${_sanitizeData(err.response?.data)}');
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final sanitized = Map<String, dynamic>.from(data);
      for (final key in ['password', 'currentPassword', 'newPassword', 'token', 'accessToken', 'authorization']) {
        if (sanitized.containsKey(key)) {
          sanitized[key] = '***REDACTED***';
        }
      }
      if (sanitized['user'] is Map) {
        final userMap = Map<String, dynamic>.from(sanitized['user']);
        if (userMap.containsKey('password')) {
          userMap['password'] = '***REDACTED***';
        }
        sanitized['user'] = userMap;
      }
      return sanitized;
    }
    return data;
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Options? options,
  }) =>
      _request('GET', path, queryParameters: query, cancelToken: cancelToken, options: options);

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Options? options,
  }) =>
      _request('POST', path, body: body, queryParameters: query, cancelToken: cancelToken, options: options);

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Options? options,
  }) =>
      _request('PUT', path, body: body, queryParameters: query, cancelToken: cancelToken, options: options);

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Options? options,
  }) =>
      _request('PATCH', path, body: body, queryParameters: query, cancelToken: cancelToken, options: options);

  Future<ApiResponse> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
    Options? options,
  }) =>
      _request('DELETE', path, body: body, queryParameters: query, cancelToken: cancelToken, options: options);

  /// Upload a single file via multipart/form-data.
  Future<ApiResponse> uploadFile(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
      if (extraFields != null) ...extraFields,
    });

    return _request(
      'POST',
      path,
      body: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: options,
    );
  }

  /// Upload multiple files via multipart/form-data.
  Future<ApiResponse> uploadMultipleFiles(
    String path, {
    required List<String> filePaths,
    String fieldName = 'files',
    Map<String, dynamic>? extraFields,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    final multipartFiles = <MultipartFile>[];
    for (final p in filePaths) {
      final fileName = p.split('/').last;
      multipartFiles.add(await MultipartFile.fromFile(p, filename: fileName));
    }

    final formData = FormData.fromMap({
      fieldName: multipartFiles,
      if (extraFields != null) ...extraFields,
    });

    return _request(
      'POST',
      path,
      body: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: options,
    );
  }

  Future<ApiResponse> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: (options ?? Options()).copyWith(method: method),
      );

      return ApiResponse(response.statusCode ?? 200, response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw ServerException(e.toString());
    }
  }

  NetworkException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const RequestTimeoutException();
    }

    if (error.type == DioExceptionType.connectionError) {
      return const NoConnectionException();
    }

    final response = error.response;
    if (response == null) {
      return const NoConnectionException();
    }

    final code = response.statusCode ?? 500;
    final data = response.data;

    String? message;
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    }

    if (code == 401) {
      onUnauthorized?.call();
      return UnauthorizedException(message ?? 'Your session has expired. Please log in again.');
    }

    if (code >= 500) {
      return ServerException(
          message ?? 'Something went wrong on our side. Please try again later.', code);
    }

    return BadRequestException(message ?? 'Request failed ($code).', statusCode: code);
  }
}

