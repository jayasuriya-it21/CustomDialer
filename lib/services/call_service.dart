import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../screens/incoming_call_screen.dart';
import '../screens/in_call_screen.dart';
import '../main.dart';
import 'contact_service.dart';

class CallService {
  static const MethodChannel _channel = MethodChannel('com.example.google_dialer/incall');
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final ValueNotifier<String> callState = ValueNotifier('idle');
  final ValueNotifier<bool> canMerge = ValueNotifier(false);
  final ContactService _contactService = ContactService();

  // ---- Dialer Role ----

  Future<void> requestDefaultDialer() async {
    try {
      await _channel.invokeMethod('requestDefaultDialer');
    } catch (e) {
      debugPrint("Default dialer request failed: $e");
    }
  }

  // ---- Call Management ----

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

  // ---- Audio Routing ----

  Future<void> toggleSpeaker(bool enable) async {
    try { await _channel.invokeMethod('toggleSpeaker', {'enable': enable}); } catch (_) {}
  }

  Future<void> toggleMute(bool enable) async {
    try { await _channel.invokeMethod('toggleMute', {'enable': enable}); } catch (_) {}
  }

  Future<void> setAudioRoute(int route) async {
    try { await _channel.invokeMethod('setAudioRoute', {'route': route}); } catch (_) {}
  }

  Future<bool> isBluetoothAvailable() async {
    try {
      final r = await _channel.invokeMethod('isBluetoothAvailable');
      return r == true;
    } catch (_) { return false; }
  }

  // ---- Call Log ----

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

  Future<void> deleteCallLog(String id) async {
    try { await _channel.invokeMethod('deleteCallLog', {'id': id}); } catch (_) {}
  }

  // ---- Settings Intents ----

  Future<void> openCallForwardingSettings() async {
    try { await _channel.invokeMethod('openCallForwardingSettings'); } catch (_) {}
  }

  Future<void> openBlockedNumbers() async {
    try { await _channel.invokeMethod('openBlockedNumbers'); } catch (_) {}
  }

  Future<void> openRingtonePicker() async {
    try { await _channel.invokeMethod('openRingtonePicker'); } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getSimInfo() async {
    try {
      final result = await _channel.invokeMethod('getSimInfo');
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ---- Event Listener ----

  bool _callScreenShowing = false;

  void listenToCallEvents() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onIncomingCall':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final number = args['number'] as String? ?? 'Unknown';
          final stateStr = args['stateStr'] as String? ?? 'unknown';
          callState.value = stateStr;

          if (_callScreenShowing) break; // Prevent double-push

          // Lookup contact name asynchronously
          final callerName = await _contactService.lookupName(number);

          if (stateStr == 'ringing') {
            _navigateToIncomingScreen(callerName, number);
          } else {
            _navigateToInCallScreen(callerName, isIncoming: false);
          }
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
          _callScreenShowing = false;
          final nav = navigatorKey.currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          }
          break;
      }
    });
  }

  void _navigateToIncomingScreen(String callerName, String callerNumber) {
    _callScreenShowing = true;
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, _, _) => IncomingCallScreen(
            callerName: callerName,
            callerNumber: callerNumber,
          ),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 150),
        ),
      );
    }
  }

  void _navigateToInCallScreen(String callerName, {bool isIncoming = false}) {
    _callScreenShowing = true;
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (_, _, _) => InCallScreen(
            callerName: callerName,
            isIncoming: isIncoming,
          ),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }
}
