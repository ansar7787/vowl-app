import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class KidsFeedbackOverlay extends StatelessWidget {
  final bool isCorrect;
  final int attempts;
  final VoidCallback onTap;

  const KidsFeedbackOverlay({
    super.key,
    this.isCorrect = true,
    this.attempts = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _KidsFeedbackOverlayContent(isCorrect: isCorrect);
  }
}

class _KidsFeedbackOverlayContent extends StatefulWidget {
  final bool isCorrect;

  const _KidsFeedbackOverlayContent({
    required this.isCorrect,
  });

  @override
  State<_KidsFeedbackOverlayContent> createState() => _KidsFeedbackOverlayContentState();
}

class _KidsFeedbackOverlayContentState extends State<_KidsFeedbackOverlayContent> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    if (widget.isCorrect) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // CENTER ANIMATION
            Center(
              child: widget.isCorrect 
                ? _buildCorrectAnimation()
                : _buildWrongAnimation(),
            ),

            // CONFETTI
            if (widget.isCorrect)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
                  createParticlePath: _drawCircle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectAnimation() {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981), // Emerald 500
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 8.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857), // Emerald 700
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Icon(Icons.star_rounded, color: Colors.white, size: 80.sp),
    ).animate()
      .scale(curve: Curves.elasticOut, duration: 800.ms)
      .then(delay: 400.ms)
      .scale(begin: const Offset(1, 1), end: const Offset(0.0, 0.0), curve: Curves.easeInBack, duration: 300.ms);
  }

  Widget _buildWrongAnimation() {
    return Container(
      padding: EdgeInsets.all(32.r),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444), // Red 500
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 8.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB91C1C), // Red 700
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Icon(Icons.close_rounded, color: Colors.white, size: 80.sp),
    ).animate()
      .scale(curve: Curves.elasticOut, duration: 600.ms)
      .shake(hz: 4, curve: Curves.easeInOutCubic, duration: 400.ms)
      .then(delay: 200.ms)
      .scale(begin: const Offset(1, 1), end: const Offset(0.0, 0.0), curve: Curves.easeInBack, duration: 300.ms);
  }

  Path _drawCircle(Size size) {
    final path = Path();
    final double radius = size.width / 2;
    path.addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius));
    return path;
  }
}
