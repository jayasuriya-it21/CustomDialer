import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/call_service.dart';
import '../widgets/contact_avatar.dart';
import 'in_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  final CallService _callService = CallService();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Lock screen on with full brightness
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _answer() async {
    HapticFeedback.mediumImpact();
    await _callService.answerCall();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => InCallScreen(
            callerName: widget.callerName,
            isIncoming: true,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  Future<void> _decline() async {
    HapticFeedback.heavyImpact();
    await _callService.rejectCall();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Caller avatar with pulsing ring
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF34A853).withOpacity(0.35),
                    width: 3,
                  ),
                ),
                child: ContactAvatar(name: widget.callerName, radius: 56),
              ),
            ),
            const SizedBox(height: 28),

            // Caller name
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Caller number (if different from name)
            if (widget.callerNumber != widget.callerName)
              Text(
                widget.callerNumber,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 8),

            // "Incoming call" label
            Text(
              'Incoming call',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),

            const Spacer(flex: 3),

            // Quick reply
            TextButton.icon(
              onPressed: () {
                // Open SMS intent
              },
              icon: Icon(Icons.message_outlined, color: Colors.white.withOpacity(0.6), size: 18),
              label: Text('Reply', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            ),

            const SizedBox(height: 32),

            // Answer / Decline buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline
                  _callActionButton(
                    icon: Icons.call_end_rounded,
                    color: Colors.red,
                    label: 'Decline',
                    onTap: _decline,
                  ),
                  // Answer
                  _callActionButton(
                    icon: Icons.call_rounded,
                    color: const Color(0xFF34A853),
                    label: 'Answer',
                    onTap: _answer,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _callActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: color.withOpacity(0.4),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
      ],
    );
  }
}
