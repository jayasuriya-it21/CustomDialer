import 'package:equatable/equatable.dart';

class IncomingCallState extends Equatable {
  const IncomingCallState({required this.callState});

  final String callState;

  factory IncomingCallState.initial() => const IncomingCallState(callState: 'ringing');

  IncomingCallState copyWith({String? callState}) {
    return IncomingCallState(callState: callState ?? this.callState);
  }

  @override
  List<Object?> get props => [callState];
}
