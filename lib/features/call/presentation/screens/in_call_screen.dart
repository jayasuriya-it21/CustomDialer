import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/service_locator.dart';
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
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1A2E), Color(0xFF0F0F0F), Color(0xFF0A0A0A)], stops: [0.0, 0.5, 1.0]),
          ),
          child: FadeTransition(
            opacity: _fadeCtrl,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _buildCallerInfo(callState),
                  const Spacer(),
                  if (callState.isCallAnswered) AnimatedSwitcher(duration: const Duration(milliseconds: 250), switchInCurve: Curves.easeOut, switchOutCurve: Curves.easeIn, child: _showDialpad ? _buildInCallDialpad() : _buildActionGrid(callState)),
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
        // Avatar with gradient ring
        ScaleTransition(
          scale: !callState.isCallAnswered ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF4285F4).withValues(alpha: 0.4), const Color(0xFFAB47BC).withValues(alpha: 0.4)]),
            ),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A2E),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF2D2D44), const Color(0xFF1A1A2E)]),
              ),
              child: Center(
                child: Text(
                  _getInitials(widget.callerName),
                  style: const TextStyle(color: Colors.white70, fontSize: 38, fontWeight: FontWeight.w300),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

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
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (_, v, _) => Opacity(
                  opacity: v,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                  ),
                ),
              ),
            Text(
              callState.isCallAnswered && callState.callStatus.isEmpty ? _formatTime() : callState.callStatus,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 15, fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: 1.0),
            ),
          ],
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
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
        width: 85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? bgActive : Colors.white.withValues(alpha: 0.08),
                boxShadow: isActive ? [BoxShadow(color: (activeColor ?? Colors.white).withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1)] : null,
              ),
              child: Icon(icon, color: isActive ? fgActive : Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54),
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
                  width: 68,
                  height: 54,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w300),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEndCallButton() {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton.large(onPressed: _disconnect, elevation: 0, backgroundColor: cs.error, foregroundColor: cs.onError, child: const Icon(Icons.call_end_rounded, size: 36));
  }
}
