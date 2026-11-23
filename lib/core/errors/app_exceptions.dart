/// Base class for every error that should be shown to the user.
/// Providers catch [AppException] and display [message].
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Business-level auth failure (wrong password, email already used, ...).
class AuthException extends AppException {
  const AuthException(super.message);
}
