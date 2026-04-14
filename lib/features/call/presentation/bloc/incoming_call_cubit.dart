import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/call_service.dart';
import '../../../../services/contact_service.dart';
import 'incoming_call_state.dart';

class IncomingCallCubit extends Cubit<IncomingCallState> {
  IncomingCallCubit(this._callService, this._contactService) : super(IncomingCallState.initial());

  final CallService _callService;
  final ContactService _contactService;

  void initialize() {
    _callService.callState.addListener(_onCallStateChanged);
  }

  void _onCallStateChanged() {
    emit(state.copyWith(callState: _callService.callState.value));
  }

  Future<void> answer() {
    return _callService.answerCall();
  }

  Future<void> decline() {
    return _callService.rejectCall();
  }

  Future<void> replyWithMessage(String number) {
    return _contactService.openSms(number);
  }

  @override
  Future<void> close() {
    _callService.callState.removeListener(_onCallStateChanged);
    return super.close();
  }
}
