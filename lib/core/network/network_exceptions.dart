import 'package:bookease/core/errors/app_exceptions.dart';

class NetworkException extends AppException {
  final int? statusCode;
  const NetworkException(super.message, {this.statusCode});
}

class NoConnectionException extends NetworkException {
  const NoConnectionException()
      : super('No internet connection. Please check your network and try again.');
}

class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException()
      : super('The request timed out. Please try again.');
}

/// 401 - missing/expired JWT.
class UnauthorizedException extends NetworkException {
  const UnauthorizedException([String message = 'Your session has expired. Please log in again.'])
      : super(message, statusCode: 401);
}

/// 4xx (except 401) - validation or business-rule error from the API.
class BadRequestException extends NetworkException {
  const BadRequestException(super.message, {super.statusCode});
}

/// 5xx
class ServerException extends NetworkException {
  const ServerException([String message = 'Something went wrong on our side. Please try again later.', int? statusCode])
      : super(message, statusCode: statusCode);
}

class ParseException extends NetworkException {
  const ParseException() : super('Unexpected response from server.');
}
