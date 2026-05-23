import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../widgets/contact_avatar.dart';
import '../bloc/in_call_cubit.dart';
import '../bloc/in_call_state.dart';

class InCallScreen extends StatefulWidget {
  final String callerName;
  final bool isIncoming;

  const InCallScreen({super.key, required this.callerName, this.isIncoming = false});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> with TickerProviderStateMixin {
  late final InCallCubit _inCallCubit;
  StreamSubscription<InCallState>? _inCallSub;
  bool _showDialpad = false;
  bool _timerStarted = false;

  Timer? _callTimer;
  int _callSeconds = 0;

  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.06).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _inCallCubit = getIt<InCallCubit>();
    _inCallCubit.initialize(callerName: widget.callerName, isIncoming: widget.isIncoming);

    if (_inCallCubit.state.isCallAnswered) {
      _timerStarted = true;
      _startTimer();
      _pulseCtrl.stop();
    }

    _inCallSub = _inCallCubit.stream.listen((state) {
      if (!mounted) {
        return;
      }
      if (state.isCallAnswered && !_timerStarted) {
        _timerStarted = true;
        _startTimer();
        _pulseCtrl.stop();
      }
      if (state.callStatus == 'Call ended') {
        _callTimer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _inCallSub?.cancel();
    _inCallCubit.close();
    _callTimer?.cancel();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
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
    await _inCallCubit.disconnect();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    await _inCallCubit.toggleMute();
  }

  Future<void> _toggleSpeaker() async {
    HapticFeedback.lightImpact();
    await _inCallCubit.toggleSpeaker();
  }

  Future<void> _toggleHold() async {
    HapticFeedback.lightImpact();
    await _inCallCubit.toggleHold();
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.lightImpact();
    final wasRecording = _inCallCubit.state.isRecording;
    await _inCallCubit.toggleRecording();
    if (wasRecording && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recording saved'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _onDtmf(String digit) {
    HapticFeedback.lightImpact();
    _inCallCubit.sendDtmf(digit);
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final callState = _inCallCubit.state;

    return BlocProvider.value(
      value: _inCallCubit,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.4,
              colors: [
                Color(0xFF1E2638), // Deep slate blue highlight
                Color(0xFF0E121E), // Dark indigo gray
                Color(0xFF07080D), // Pure obsidian dark
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _buildCallerInfo(callState),
                  const Spacer(),
                  if (callState.isCallAnswered)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _showDialpad ? _buildInCallDialpad() : _buildActionGrid(callState),
                    ),
                  const SizedBox(height: 36),
                  _buildEndCallButton(),
                  const SizedBox(height: 52),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallerInfo(InCallState callState) {
    final isRecording = callState.isRecording;
    return Column(
      children: [
        // Avatar with gradient glowing ring
        ScaleTransition(
          scale: !callState.isCallAnswered ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4285F4).withValues(alpha: 0.5),
                  const Color(0xFFAB47BC).withValues(alpha: 0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.18),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF07080D),
              ),
              child: ContactAvatar(
                name: widget.callerName,
                radius: 50,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.callerName,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300, letterSpacing: 0.5),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),

        // Status / Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRecording)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _RecordingIndicatorDot(),
              ),
            Text(
              callState.isCallAnswered && callState.callStatus.isEmpty ? _formatTime() : callState.callStatus.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGrid(InCallState callState) {
    final isRecording = callState.isRecording;
    return Padding(
      key: const ValueKey('actions'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(icon: callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, label: 'Mute', isActive: callState.isMuted, onTap: _toggleMute),
              _actionBtn(icon: Icons.dialpad_rounded, label: 'Keypad', onTap: () => setState(() => _showDialpad = true)),
              _actionBtn(icon: callState.isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded, label: 'Speaker', isActive: callState.isSpeaker, onTap: _toggleSpeaker),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(icon: Icons.add_call, label: 'Add call', onTap: () {}),
              _actionBtn(icon: callState.isOnHold ? Icons.play_arrow_rounded : Icons.pause_rounded, label: callState.isOnHold ? 'Resume' : 'Hold', isActive: callState.isOnHold, onTap: _toggleHold),
              _actionBtn(icon: isRecording ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded, label: isRecording ? 'Stop' : 'Record', isActive: isRecording, activeColor: Colors.red, onTap: _toggleRecording),
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
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? bgActive : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: isActive ? bgActive.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: isActive ? [BoxShadow(color: (activeColor ?? Colors.white).withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)] : null,
              ),
              child: Icon(icon, color: isActive ? fgActive : Colors.white.withValues(alpha: 0.85), size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.55),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
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
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits
            .map(
              (d) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: InkWell(
                    onTap: () => _onDtmf(d),
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEndCallButton() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cs.error.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.large(
        onPressed: _disconnect,
        elevation: 0,
        backgroundColor: cs.error,
        foregroundColor: cs.onError,
        shape: const CircleBorder(),
        child: const Icon(Icons.call_end_rounded, size: 36),
      ),
    );
  }
}

class _RecordingIndicatorDot extends StatefulWidget {
  @override
  State<_RecordingIndicatorDot> createState() => _RecordingIndicatorDotState();
}

class _RecordingIndicatorDotState extends State<_RecordingIndicatorDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent,
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
