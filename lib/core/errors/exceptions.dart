class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'UnauthorizedException: Session expired. Please login again.';
}

class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'NetworkException: No internet connection.';
}

class InsufficientBalanceException implements Exception {
  const InsufficientBalanceException();

  @override
  String toString() => 'InsufficientBalanceException: Insufficient wallet balance.';
}