import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/call_service.dart';
import '../../../../services/recording_service.dart';
import 'in_call_state.dart';

class InCallCubit extends Cubit<InCallState> {
  InCallCubit(this._callService, this._recordingService) : super(InCallState.initial(isIncoming: false));

  final CallService _callService;
  final RecordingService _recordingService;

  String _callerName = '';

  void initialize({required String callerName, required bool isIncoming}) {
    _callerName = callerName;
    emit(InCallState.initial(isIncoming: isIncoming).copyWith(isRecording: _recordingService.isRecording));

    _callService.callState.addListener(_onCallStateChanged);
    _callService.setProximityEnabled(true);
  }

  void _onCallStateChanged() {
    final nativeState = _callService.callState.value;

    switch (nativeState) {
      case 'active':
        final nextState = state.copyWith(isCallAnswered: true, callStatus: '');
        emit(nextState);
        _tryAutoRecord();
        break;
      case 'ringing':
        emit(state.copyWith(callStatus: 'Incoming call'));
        break;
      case 'dialing':
        emit(state.copyWith(callStatus: 'Calling...'));
        break;
      case 'connecting':
        emit(state.copyWith(callStatus: 'Connecting...'));
        break;
      case 'holding':
        emit(state.copyWith(callStatus: 'On hold', isOnHold: true));
        break;
      case 'disconnected':
        emit(state.copyWith(callStatus: 'Call ended'));
        _stopRecordingIfNeeded();
        break;
    }
  }

  Future<void> _tryAutoRecord() async {
    if (await _recordingService.autoRecordEnabled && !_recordingService.isRecording) {
      await _recordingService.startRecording(contactName: _callerName);
      var next = state.copyWith(isRecording: _recordingService.isRecording);
      if (!next.isSpeaker) {
        await _callService.setAudioRoute(1);
        _callService.setProximityEnabled(false);
        next = next.copyWith(isSpeaker: true);
      }
      emit(next);
    }
  }

  Future<void> _stopRecordingIfNeeded() async {
    if (_recordingService.isRecording) {
      await _recordingService.stopRecording();
      emit(state.copyWith(isRecording: false));
    }
  }

  Future<void> disconnect() async {
    await _stopRecordingIfNeeded();
    await _callService.disconnectCall();
  }

  Future<void> toggleMute() async {
    final next = !state.isMuted;
    emit(state.copyWith(isMuted: next));
    await _callService.toggleMute(next);
  }

  Future<void> toggleSpeaker() async {
    final next = !state.isSpeaker;
    if (next) {
      await _callService.setAudioRoute(1);
      _callService.setProximityEnabled(false);
    } else {
      await _callService.setAudioRoute(0);
      _callService.setProximityEnabled(true);
    }
    emit(state.copyWith(isSpeaker: next));
  }

  Future<void> toggleHold() async {
    final next = !state.isOnHold;
    if (next) {
      await _callService.holdCall();
    } else {
      await _callService.unholdCall();
    }
    emit(state.copyWith(isOnHold: next));
  }

  Future<void> toggleRecording() async {
    if (_recordingService.isRecording) {
      await _recordingService.stopRecording();
      emit(state.copyWith(isRecording: false));
      return;
    }

    final path = await _recordingService.startRecording(contactName: _callerName);
    if (path != null && !state.isSpeaker) {
      await _callService.setAudioRoute(1);
      _callService.setProximityEnabled(false);
      emit(state.copyWith(isSpeaker: true, isRecording: true));
      return;
    }

    emit(state.copyWith(isRecording: _recordingService.isRecording));
  }

  Future<void> sendDtmf(String digit) {
    return _callService.sendDtmf(digit);
  }

  @override
  Future<void> close() {
    _callService.setProximityEnabled(false);
    _callService.callState.removeListener(_onCallStateChanged);
    return super.close();
  }
}
