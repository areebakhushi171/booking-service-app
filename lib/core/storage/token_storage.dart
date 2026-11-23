import 'package:bookease/core/storage/local_storage_service.dart';

/// Holds the JWT access token.
/// NOTE: backed by SharedPreferences for now. Before production, swap the
/// internals for flutter_secure_storage (same public API).
class TokenStorage {
  static const String _keyAccessToken = 'bookease_access_token';

  final LocalStorageService _storage;
  TokenStorage(this._storage);

  String? readToken() => _storage.getString(_keyAccessToken);

  Future<void> saveToken(String token) async {
    await _storage.setString(_keyAccessToken, token);
  }

  Future<void> clear() async {
    await _storage.remove(_keyAccessToken);
  }
}
