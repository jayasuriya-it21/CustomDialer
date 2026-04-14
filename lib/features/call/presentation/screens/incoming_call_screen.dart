import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../widgets/contact_avatar.dart';
import '../bloc/incoming_call_cubit.dart';
import '../bloc/incoming_call_state.dart';
import 'in_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;

  const IncomingCallScreen({super.key, required this.callerName, required this.callerNumber});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with TickerProviderStateMixin {
  late final IncomingCallCubit _incomingCallCubit;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();

    // Pulsing avatar
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Expanding ring
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
    _ringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    // Fade in
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeCtrl.forward();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _incomingCallCubit = getIt<IncomingCallCubit>();
    _incomingCallCubit.initialize();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _fadeCtrl.dispose();
    _incomingCallCubit.close();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _answer() async {
    HapticFeedback.mediumImpact();
    await _incomingCallCubit.answer();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => InCallScreen(callerName: widget.callerName, isIncoming: true),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  Future<void> _decline() async {
    HapticFeedback.heavyImpact();
    await _incomingCallCubit.decline();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _incomingCallCubit,
      child: BlocListener<IncomingCallCubit, IncomingCallState>(
        listener: (context, state) {
          if (state.callState == 'disconnected' || state.callState == 'idle') {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: FadeTransition(
            opacity: _fadeCtrl,
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Animated ring behind avatar
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding ring animation
                        AnimatedBuilder(
                          animation: _ringAnim,
                          builder: (_, _) => Container(
                            width: 120 + (_ringAnim.value * 40),
                            height: 120 + (_ringAnim.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF34A853).withValues(alpha: 0.3 * (1 - _ringAnim.value)), width: 2),
                            ),
                          ),
                        ),
                        // Avatar
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: ContactAvatar(name: widget.callerName, radius: 52),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Caller name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.callerName,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Number (if different)
                  if (widget.callerNumber != widget.callerName) Text(widget.callerNumber, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 16)),
                  const SizedBox(height: 12),

                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white.withValues(alpha: 0.06)),
                    child: Text('Incoming call', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, letterSpacing: 0.8)),
                  ),

                  const Spacer(flex: 3),

                  // Quick reply
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TextButton.icon(
                      onPressed: () => _incomingCallCubit.replyWithMessage(widget.callerNumber),
                      icon: Icon(Icons.message_outlined, color: Colors.white.withValues(alpha: 0.5), size: 18),
                      label: Text('Reply', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                    ),
                  ),

                  // Answer / Decline
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 48, 56),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _callActionButton(icon: Icons.call_end_rounded, color: const Color(0xFFEA4335), label: 'Decline', onTap: _decline),
                        _callActionButton(icon: Icons.call_rounded, color: const Color(0xFF34A853), label: 'Answer', onTap: _answer),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _callActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: color.withValues(alpha: 0.5),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: Colors.white24,
            child: SizedBox(
              width: 76,
              height: 76,
              child: Center(child: Icon(icon, color: Colors.white, size: 34)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}
