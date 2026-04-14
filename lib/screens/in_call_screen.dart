import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/call_service.dart';

class InCallScreen extends StatefulWidget {
  final String callerName;
  final bool isIncoming;

  const InCallScreen({super.key, required this.callerName, this.isIncoming = false});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> with TickerProviderStateMixin {
  final CallService _callService = CallService();

  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isRecording = false;
  bool _isOnHold = false;
  bool _showDialpad = false;
  bool _isCallAnswered = false;

  late final AudioRecorder _audioRecorder;

  // Call timer - only starts after call is answered/connected
  Timer? _callTimer;
  int _callSeconds = 0;

  // Animations
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeCtrl;

  String _callStatus = '';

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();

    _callStatus = widget.isIncoming ? 'Incoming call' : 'Calling...';

    if (!widget.isIncoming) {
      _isCallAnswered = false; // will become true when state=active
    }

    _listenCallState();
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
          break;
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _audioRecorder.dispose();
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
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---- Actions ----

  Future<void> _answerCall() async {
    HapticFeedback.mediumImpact();
    await _callService.answerCall();
    setState(() {
      _isCallAnswered = true;
      _callStatus = '';
    });
    _startTimer();
  }

  Future<void> _rejectCall() async {
    HapticFeedback.heavyImpact();
    if (_isRecording) await _audioRecorder.stop();
    await _callService.rejectCall();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _disconnect() async {
    HapticFeedback.heavyImpact();
    if (_isRecording) await _audioRecorder.stop();
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
      setState(() {
        _isSpeaker = false;
      });
      await _callService.setAudioRoute(0);
    } else {
      setState(() {
        _isSpeaker = true;
      });
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
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recording saved: ${path.split('/').last}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final ts = DateTime.now().millisecondsSinceEpoch;
          final path = '${dir.path}/call_$ts.m4a';

          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
          setState(() => _isRecording = true);

          // Auto-enable speaker for 2-way capture
          if (!_isSpeaker) {
            setState(() {
              _isSpeaker = true;
            });
            await _callService.setAudioRoute(1);
          }
        }
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildCallerInfo(),
              const Spacer(),
              if (_isCallAnswered) ...[if (_showDialpad) _buildInCallDialpad() else _buildActionGrid(), const SizedBox(height: 24)],
              _buildCallControls(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      children: [
        // Avatar with pulse animation for incoming
        ScaleTransition(
          scale: widget.isIncoming && !_isCallAnswered ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.blue.withValues(alpha: 0.25), Colors.purple.withValues(alpha: 0.25)]),
            ),
            child: const Icon(Icons.person_rounded, size: 44, color: Colors.white60),
          ),
        ),
        const SizedBox(height: 18),

        // Caller name
        Text(
          widget.callerName,
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w400),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Status / Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
              ),
            Text(_isCallAnswered && _callStatus.isEmpty ? _formatTime() : _callStatus, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, label: 'Mute', isActive: _isMuted, onTap: _toggleMute),
              _actionBtn(icon: Icons.dialpad_rounded, label: 'Keypad', onTap: () => setState(() => _showDialpad = true)),
              _actionBtn(icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded, label: 'Speaker', isActive: _isSpeaker, onTap: _toggleSpeaker),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(icon: Icons.add_call, label: 'Add call', onTap: () {}),
              _actionBtn(icon: _isOnHold ? Icons.play_arrow_rounded : Icons.pause_rounded, label: _isOnHold ? 'Resume' : 'Hold', isActive: _isOnHold, onTap: _toggleHold),
              _actionBtn(icon: _isRecording ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded, label: _isRecording ? 'Stop' : 'Record', isActive: _isRecording, activeColor: Colors.red, onTap: _toggleRecording),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required VoidCallback onTap, bool isActive = false, Color? activeColor}) {
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? bgActive : Colors.transparent),
              child: Icon(icon, color: isActive ? fgActive : Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInCallDialpad() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60),
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
          .map(
            (d) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onDtmf(d),
                borderRadius: BorderRadius.circular(32),
                splashColor: Colors.white10,
                child: SizedBox(
                  width: 64,
                  height: 52,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCallControls() {
    if (widget.isIncoming && !_isCallAnswered) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _callBtn(Icons.call_end_rounded, Colors.red, _rejectCall, label: 'Decline'),
          _callBtn(Icons.call_rounded, const Color(0xFF34A853), _answerCall, label: 'Answer'),
        ],
      );
    }
    return _callBtn(Icons.call_end_rounded, Colors.red, _disconnect, size: 68);
  }

  Widget _callBtn(IconData icon, Color color, VoidCallback onTap, {double size = 60, String? label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: color.withValues(alpha: 0.35),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(icon, color: Colors.white, size: size * 0.42),
              ),
            ),
          ),
        ),
        if (label != null) ...[const SizedBox(height: 10), Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14))],
      ],
    );
  }
}
