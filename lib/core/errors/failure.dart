import 'package:equatable/equatable.dart';

class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}
