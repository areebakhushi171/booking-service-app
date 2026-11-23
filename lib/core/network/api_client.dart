import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:bookease/core/network/api_response.dart';
import 'package:bookease/core/network/network_config.dart';
import 'package:bookease/core/network/network_exceptions.dart';
import 'package:bookease/core/storage/token_storage.dart';

/// Reusable REST client: base URL, JSON, Bearer token, timeouts and error mapping.
/// Only used when NetworkConfig.useRemoteBackend is true.
class ApiClient {
  final http.Client _http;
  final TokenStorage _tokens;

  /// Called when the API answers 401 (e.g. to force logout).
  void Function()? onUnauthorized;

  ApiClient(this._tokens, {http.Client? client}) : _http = client ?? http.Client();

  Future<ApiResponse> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResponse> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<ApiResponse> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<ApiResponse> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<ApiResponse> delete(String path) => _send('DELETE', path);

  Uri _uri(String path, Map<String, String>? query) {
    final base = NetworkConfig.baseUrl.endsWith('/')
        ? NetworkConfig.baseUrl.substring(0, NetworkConfig.baseUrl.length - 1)
        : NetworkConfig.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> _headers() {
    final token = _tokens.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Object? _sanitizeBody(Object? body) {
    if (body == null) return null;
    if (body is Map) {
      final sanitized = Map<String, dynamic>.from(body);
      for (final key in ['password', 'currentPassword', 'newPassword', 'token', 'accessToken', 'authorization']) {
        if (sanitized.containsKey(key)) {
          sanitized[key] = '***REDACTED***';
        }
      }
      return sanitized;
    }
    return body;
  }

  dynamic _sanitizeResponse(dynamic decoded) {
    if (decoded is Map) {
      final sanitized = Map<String, dynamic>.from(decoded);
      for (final key in ['token', 'accessToken', 'password']) {
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
    return decoded;
  }

  Future<ApiResponse> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = _uri(path, query);
    final request = http.Request(method, uri)
      ..headers.addAll(_headers());
    if (body != null) request.body = jsonEncode(body);

    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    if (kDebugMode) {
      debugPrint('🌐 [API REQ] $method $uri');
      debugPrint('⏱️ [TIMESTAMP] $startTime');
      if (body != null) {
        debugPrint('📦 [REQ BODY] ${jsonEncode(_sanitizeBody(body))}');
      }
    }

    try {
      final streamed = await _http
          .send(request)
          .timeout(NetworkConfig.connectTimeout + NetworkConfig.receiveTimeout);
      final response = await http.Response.fromStream(streamed);
      stopwatch.stop();

      if (kDebugMode) {
        debugPrint('📥 [API RES] $method $uri');
        debugPrint('🔢 [STATUS] ${response.statusCode}');
        debugPrint('⏱️ [DURATION] ${stopwatch.elapsedMilliseconds}ms');
        if (response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body);
            debugPrint('📄 [RES BODY] ${jsonEncode(_sanitizeResponse(decoded))}');
          } catch (_) {
            debugPrint('📄 [RES BODY] ${response.body}');
          }
        }
      }

      return _handle(response);
    } on TimeoutException catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('❌ [API ERROR] $method $uri - Timeout after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      throw const RequestTimeoutException();
    } on http.ClientException catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('❌ [API ERROR] $method $uri - ClientException after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      throw const NoConnectionException();
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint('❌ [API ERROR] $method $uri - Exception after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      rethrow;
    }
  }

  ApiResponse _handle(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw const ParseException();
        }
      }
    }

    final code = response.statusCode;
    if (code >= 200 && code < 300) return ApiResponse(code, decoded);

    final message = decoded is Map && decoded['message'] is String
        ? decoded['message'] as String
        : null;

    if (code == 401) {
      onUnauthorized?.call();
      throw UnauthorizedException(message ?? 'Your session has expired. Please log in again.');
    }
    if (code >= 500) {
      throw ServerException(
          message ?? 'Something went wrong on our side. Please try again later.', code);
    }
    throw BadRequestException(message ?? 'Request failed ($code).', statusCode: code);
  }
}
