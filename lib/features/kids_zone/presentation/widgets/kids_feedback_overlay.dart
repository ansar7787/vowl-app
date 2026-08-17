import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';

class KidsFeedbackOverlay extends StatelessWidget {
  final bool isCorrect;
  final int attempts;
  final VoidCallback onTap;
  final String? explanation;

  const KidsFeedbackOverlay({
    super.key,
    this.isCorrect = true,
    this.attempts = 1,
    required this.onTap,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return _KidsFeedbackOverlayContent(
      isCorrect: isCorrect,
      explanation: explanation,
    );
  }
}

class _KidsFeedbackOverlayContent extends StatefulWidget {
  final bool isCorrect;
  final String? explanation;

  const _KidsFeedbackOverlayContent({
    required this.isCorrect,
    this.explanation,
  });

  @override
  State<_KidsFeedbackOverlayContent> createState() =>
      _KidsFeedbackOverlayContentState();
}

class _KidsFeedbackOverlayContentState
    extends State<_KidsFeedbackOverlayContent> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.isCorrect
                      ? _buildCorrectAnimation()
                      : _buildWrongAnimation(),
                  if (!widget.isCorrect && widget.explanation != null) ...[
                    SizedBox(height: 32.h),
                    _buildExplanationCard(context, widget.explanation!),
                  ],
                ],
              ),
            ),

            // CONFETTI
            if (widget.isCorrect)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                    Colors.yellow,
                  ],
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
          padding: EdgeInsets.all(
            16.r,
          ), // Reduced padding since Lottie has its own whitespace
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
          child: Lottie.asset(
            'assets/animations/success.json',
            width: 100.sp,
            height: 100.sp,
            repeat: false,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.star_rounded, color: Colors.white, size: 80.sp),
          ),
        )
        .animate()
        .scale(curve: Curves.elasticOut, duration: 800.ms)
        .then(delay: 400.ms)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.0, 0.0),
          curve: Curves.easeInBack,
          duration: 300.ms,
        );
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
        )
        .animate()
        .scale(curve: Curves.elasticOut, duration: 600.ms)
        .shake(hz: 4, curve: Curves.easeInOutCubic, duration: 400.ms)
        .then(delay: 200.ms)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.0, 0.0),
          curve: Curves.easeInBack,
          duration: 300.ms,
        );
  }

  Path _drawCircle(Size size) {
    final path = Path();
    final double radius = size.width / 2;
    path.addOval(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius),
    );
    return path;
  }

  Widget _buildExplanationCard(BuildContext context, String explanation) {
    return Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.grey.shade300, width: 3.w),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade400, offset: Offset(0, 6.h)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 28.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "EXPLANATION",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                explanation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(
          begin: 0.2,
          curve: Curves.easeOutBack,
          delay: 600.ms,
          duration: 400.ms,
        );
  }
}


