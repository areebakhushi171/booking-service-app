/// Network configuration. The base URL is NEVER hard-coded; pass it at build time:
///
///   flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
///
/// With no value the app keeps using local mock/storage data sources.
class NetworkConfig {
  NetworkConfig._();

  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/api');

  static bool get useRemoteBackend => baseUrl.isNotEmpty;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
