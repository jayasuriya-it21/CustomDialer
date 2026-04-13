import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/call_service.dart';
import '../services/recording_service.dart';

class InCallScreen extends StatefulWidget {
  final String callerName;
  final bool isIncoming;

  const InCallScreen({
    super.key,
    required this.callerName,
    this.isIncoming = false,
  });

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen>
    with TickerProviderStateMixin {
  final CallService _callService = CallService();
  final RecordingService _recordingService = RecordingService();

  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isOnHold = false;
  bool _showDialpad = false;
  bool _isCallAnswered = false;

  Timer? _callTimer;
  int _callSeconds = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeCtrl;

  String _callStatus = '';

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();

    _callStatus = widget.isIncoming ? 'Incoming call' : 'Calling...';

    if (widget.isIncoming) {
      _isCallAnswered = true; // Already answered from IncomingCallScreen
      _startTimer();
      _callStatus = '';
    }

    _listenCallState();
    _checkAutoRecord();
  }

  Future<void> _checkAutoRecord() async {
    if (await _recordingService.autoRecordEnabled) {
      // Will start recording when call becomes active
    }
  }

  void _listenCallState() {
    _callService.callState.addListener(_onCallStateChanged);
  }

  void _onCallStateChanged() {
    final state = _callService.callState.value;
    if (!mounted) return;

    setState(() {
      switch (state) {
        case 'active':
          if (!_isCallAnswered) {
            _isCallAnswered = true;
            _startTimer();
          }
          _callStatus = '';
          // Auto-record if enabled
          _tryAutoRecord();
          break;
        case 'ringing':
          _callStatus = 'Incoming call';
          break;
        case 'dialing':
          _callStatus = 'Calling...';
          break;
        case 'connecting':
          _callStatus = 'Connecting...';
          break;
        case 'holding':
          _callStatus = 'On hold';
          break;
        case 'disconnected':
          _callStatus = 'Call ended';
          _stopRecordingIfNeeded();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _tryAutoRecord() async {
    if (await _recordingService.autoRecordEnabled &&
        !_recordingService.isRecording) {
      await _recordingService.startRecording(
          contactName: widget.callerName);
      if (mounted) setState(() {});
      // Auto-enable speaker
      if (!_isSpeaker) {
        _isSpeaker = true;
        await _callService.setAudioRoute(1);
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _stopRecordingIfNeeded() async {
    if (_recordingService.isRecording) {
      await _recordingService.stopRecording();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _callService.callState.removeListener(_onCallStateChanged);
    super.dispose();
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  String _formatTime() {
    final h = _callSeconds ~/ 3600;
    final m = (_callSeconds % 3600) ~/ 60;
    final s = _callSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---- Actions ----

  Future<void> _disconnect() async {
    HapticFeedback.heavyImpact();
    await _stopRecordingIfNeeded();
    await _callService.disconnectCall();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    setState(() => _isMuted = !_isMuted);
    await _callService.toggleMute(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    HapticFeedback.lightImpact();
    if (_isSpeaker) {
      setState(() => _isSpeaker = false);
      await _callService.setAudioRoute(0);
    } else {
      setState(() => _isSpeaker = true);
      await _callService.setAudioRoute(1);
    }
  }

  Future<void> _toggleHold() async {
    HapticFeedback.lightImpact();
    if (_isOnHold) {
      await _callService.unholdCall();
    } else {
      await _callService.holdCall();
    }
    setState(() => _isOnHold = !_isOnHold);
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.lightImpact();
    try {
      if (_recordingService.isRecording) {
        final path = await _recordingService.stopRecording();
        if (path != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording saved: ${path.split('/').last}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        final path = await _recordingService.startRecording(
            contactName: widget.callerName);
        if (path != null && !_isSpeaker) {
          setState(() => _isSpeaker = true);
          await _callService.setAudioRoute(1);
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Recording error: $e");
    }
  }

  void _onDtmf(String digit) {
    HapticFeedback.lightImpact();
    _callService.sendDtmf(digit);
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final isRecording = _recordingService.isRecording;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildCallerInfo(isRecording),
              const Spacer(),
              if (_isCallAnswered) ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showDialpad
                      ? _buildInCallDialpad()
                      : _buildActionGrid(isRecording),
                ),
                const SizedBox(height: 32),
              ],
              _buildEndCallButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallerInfo(bool isRecording) {
    return Column(
      children: [
        ScaleTransition(
          scale: !_isCallAnswered
              ? _pulseAnim
              : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4285F4).withOpacity(0.3),
                  const Color(0xFFAB47BC).withOpacity(0.3),
                ],
              ),
            ),
            child: const Icon(Icons.person_rounded,
                size: 48, color: Colors.white60),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.callerName,
          style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRecording)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.red),
              ),
            Text(
              _isCallAnswered && _callStatus.isEmpty
                  ? _formatTime()
                  : _callStatus,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                  fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGrid(bool isRecording) {
    return Padding(
      key: const ValueKey('actions'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: 'Mute',
                isActive: _isMuted,
                onTap: _toggleMute,
              ),
              _actionBtn(
                icon: Icons.dialpad_rounded,
                label: 'Keypad',
                onTap: () => setState(() => _showDialpad = true),
              ),
              _actionBtn(
                icon: _isSpeaker
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                label: 'Speaker',
                isActive: _isSpeaker,
                onTap: _toggleSpeaker,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(
                icon: Icons.add_call,
                label: 'Add call',
                onTap: () {},
              ),
              _actionBtn(
                icon: _isOnHold
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: _isOnHold ? 'Resume' : 'Hold',
                isActive: _isOnHold,
                onTap: _toggleHold,
              ),
              _actionBtn(
                icon: isRecording
                    ? Icons.stop_circle_rounded
                    : Icons.fiber_manual_record_rounded,
                label: isRecording ? 'Stop' : 'Record',
                isActive: isRecording,
                activeColor: Colors.red,
                onTap: _toggleRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final bgActive = activeColor ?? Colors.white;
    final fgActive = activeColor != null ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? bgActive : Colors.white.withOpacity(0.08),
              ),
              child: Icon(icon,
                  color: isActive ? fgActive : Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInCallDialpad() {
    return Column(
      key: const ValueKey('dialpad'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white60),
              onPressed: () => setState(() => _showDialpad = false),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              _dtmfRow(['1', '2', '3']),
              _dtmfRow(['4', '5', '6']),
              _dtmfRow(['7', '8', '9']),
              _dtmfRow(['*', '0', '#']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dtmfRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onDtmf(d),
                  borderRadius: BorderRadius.circular(32),
                  splashColor: Colors.white10,
                  child: SizedBox(
                    width: 64,
                    height: 52,
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w300)),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEndCallButton() {
    return Material(
      color: Colors.red,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.red.withOpacity(0.4),
      child: InkWell(
        onTap: _disconnect,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 72,
          height: 72,
          child: Center(
              child: Icon(Icons.call_end_rounded,
                  color: Colors.white, size: 32)),
        ),
      ),
    );
  }
}
