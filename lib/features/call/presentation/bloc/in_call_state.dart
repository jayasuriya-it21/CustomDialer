import 'package:equatable/equatable.dart';

class InCallState extends Equatable {
  const InCallState({required this.isMuted, required this.isSpeaker, required this.isOnHold, required this.isCallAnswered, required this.callStatus, required this.isRecording});

  final bool isMuted;
  final bool isSpeaker;
  final bool isOnHold;
  final bool isCallAnswered;
  final String callStatus;
  final bool isRecording;

  factory InCallState.initial({required bool isIncoming}) => InCallState(isMuted: false, isSpeaker: false, isOnHold: false, isCallAnswered: isIncoming, callStatus: isIncoming ? '' : 'Calling...', isRecording: false);

  InCallState copyWith({bool? isMuted, bool? isSpeaker, bool? isOnHold, bool? isCallAnswered, String? callStatus, bool? isRecording}) {
    return InCallState(isMuted: isMuted ?? this.isMuted, isSpeaker: isSpeaker ?? this.isSpeaker, isOnHold: isOnHold ?? this.isOnHold, isCallAnswered: isCallAnswered ?? this.isCallAnswered, callStatus: callStatus ?? this.callStatus, isRecording: isRecording ?? this.isRecording);
  }

  @override
  List<Object?> get props => [isMuted, isSpeaker, isOnHold, isCallAnswered, callStatus, isRecording];
}
