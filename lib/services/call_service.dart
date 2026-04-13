import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../screens/in_call_screen.dart';
import '../main.dart';

class CallService {
  static const MethodChannel _channel = MethodChannel('com.example.google_dialer/incall');
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final ValueNotifier<String> callState = ValueNotifier('idle');
  final ValueNotifier<bool> canMerge = ValueNotifier(false);

  Future<void> requestDefaultDialer() async {
    try {
      await _channel.invokeMethod('requestDefaultDialer');
    } catch (e) {
      debugPrint("Default dialer request failed: $e");
    }
  }

  Future<bool> makeCall(String number) async {
    try {
      final result = await _channel.invokeMethod('makeCall', {'number': number});
      return result == true;
    } catch (e) {
      debugPrint("Make call failed: $e");
      return false;
    }
  }

  Future<void> answerCall() async {
    try { await _channel.invokeMethod('answerCall'); } catch (_) {}
  }

  Future<void> rejectCall() async {
    try { await _channel.invokeMethod('rejectCall'); } catch (_) {}
  }

  Future<void> disconnectCall() async {
    try { await _channel.invokeMethod('disconnectCall'); } catch (_) {}
  }

  Future<void> holdCall() async {
    try { await _channel.invokeMethod('holdCall'); } catch (_) {}
  }

  Future<void> unholdCall() async {
    try { await _channel.invokeMethod('unholdCall'); } catch (_) {}
  }

  Future<bool> mergeConference() async {
    try {
      final r = await _channel.invokeMethod('mergeConference');
      return r == true;
    } catch (_) { return false; }
  }

  Future<void> swapConference() async {
    try { await _channel.invokeMethod('swapConference'); } catch (_) {}
  }

  Future<void> sendDtmf(String digit) async {
    try { await _channel.invokeMethod('sendDtmf', {'digit': digit}); } catch (_) {}
  }

  Future<void> toggleSpeaker(bool enable) async {
    try { await _channel.invokeMethod('toggleSpeaker', {'enable': enable}); } catch (_) {}
  }

  Future<void> toggleMute(bool enable) async {
    try { await _channel.invokeMethod('toggleMute', {'enable': enable}); } catch (_) {}
  }

  Future<void> setAudioRoute(int route) async {
    // 0=earpiece, 1=speaker, 2=bluetooth
    try { await _channel.invokeMethod('setAudioRoute', {'route': route}); } catch (_) {}
  }

  Future<bool> isBluetoothAvailable() async {
    try {
      final r = await _channel.invokeMethod('isBluetoothAvailable');
      return r == true;
    } catch (_) { return false; }
  }

  Future<List<Map<String, dynamic>>> getCallLog() async {
    try {
      final result = await _channel.invokeMethod('getCallLog');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint("Get call log failed: $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final result = await _channel.invokeMethod('getContacts');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint("Get contacts failed: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>> getContactDetails(String number) async {
    try {
      final result = await _channel.invokeMethod('getContactDetails', {'number': number});
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return {};
  }

  Future<void> deleteCallLog(String id) async {
    try { await _channel.invokeMethod('deleteCallLog', {'id': id}); } catch (_) {}
  }

  void listenToCallEvents() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onIncomingCall':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final number = args['number'] as String? ?? 'Unknown';
          final stateStr = args['stateStr'] as String? ?? 'unknown';
          callState.value = stateStr;
          _navigateToInCallScreen(number, isIncoming: stateStr == 'ringing');
          break;
        case 'onCallStateChanged':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final stateStr = args['stateStr'] as String? ?? 'unknown';
          callState.value = stateStr;
          break;
        case 'onConferenceableCallsChanged':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          canMerge.value = args['canMerge'] as bool? ?? false;
          break;
        case 'onCallRemoved':
          callState.value = 'idle';
          final nav = navigatorKey.currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          }
          break;
      }
    });
  }

  void _navigateToInCallScreen(String callerNumber, {bool isIncoming = true}) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, __, ___) => InCallScreen(
            callerName: callerNumber,
            isIncoming: isIncoming,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }
}
