import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('Session expired. Please login again.');
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure() : super('Insufficient wallet balance.');
}