import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

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
    return _KidsFeedbackOverlayContent(isCorrect: isCorrect, attempts: attempts, onTap: onTap);
  }
}

class _KidsFeedbackOverlayContent extends StatefulWidget {
  final bool isCorrect;
  final int attempts;
  final VoidCallback onTap;

  const _KidsFeedbackOverlayContent({
    required this.isCorrect,
    required this.attempts,
    required this.onTap,
  });

  @override
  State<_KidsFeedbackOverlayContent> createState() => _KidsFeedbackOverlayContentState();
}

class _KidsFeedbackOverlayContentState extends State<_KidsFeedbackOverlayContent> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
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
    final primaryColor = widget.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final accentColor = widget.isCorrect ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B);

    return Positioned.fill(
      child: Stack(
        children: [
          // GLASSMORPHIC BLUR LAYER
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: 400.ms,
            builder: (context, value, child) {
              return BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10 * value, sigmaY: 10 * value),
                child: Container(
                  color: primaryColor.withValues(alpha: 0.15 * value),
                ),
              );
            },
          ),

          // VIBRANT GRADIENT GLOWS
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlowCircle(primaryColor.withValues(alpha: 0.3), 300),
          ).animate().scale(duration: 1.seconds, curve: Curves.easeOutBack),
          
          Positioned(
            bottom: -150,
            left: -100,
            child: _buildGlowCircle(accentColor.withValues(alpha: 0.2), 400),
          ).animate().scale(duration: 1.5.seconds, curve: Curves.easeOutBack),

          // CONTENT
          GestureDetector(
            onTap: widget.onTap,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMascotSection(context, primaryColor),
                  SizedBox(height: 40.h),
                  
                  // MAIN TITLE
                  Text(
                    widget.isCorrect ? "AWESOME!" : "OH NO!",
                    style: GoogleFonts.outfit(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Colors.black26, offset: const Offset(0, 10), blurRadius: 20),
                      ],
                    ),
                  ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),

                  SizedBox(height: 8.h),

                  // SUBTITLE
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      widget.isCorrect 
                        ? "Great job! Keep going! ✨" 
                        : (widget.attempts >= 2 
                           ? "Nice try! Let's review this later! 💡" 
                           : "Almost there! Try again! ✨"),
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),

                  if (!widget.isCorrect) ...[
                    SizedBox(height: 20.h),
                    // STRIKE INDICATOR (Two-Strike Mastery)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) {
                        final isUsed = index < widget.attempts;
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 6.w),
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: isUsed ? Colors.black26 : Colors.white24,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isUsed ? Colors.white38 : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isUsed ? Icons.close_rounded : Icons.favorite_rounded,
                            color: isUsed ? Colors.white54 : Colors.redAccent,
                            size: 24.sp,
                          ),
                        ).animate(target: isUsed ? 1 : 0).shake(duration: 500.ms).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2));
                      }),
                    ).animate().fadeIn(delay: 600.ms),
                  ],

                  SizedBox(height: 60.h),

                  // MODERN 3D BUTTON
                  ScaleButton(
                    onTap: widget.onTap,
                    child: Container(
                      width: 220.w,
                      height: 64.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(32.r),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "CONTINUE",
                              style: GoogleFonts.outfit(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 22.sp),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                ],
              ),
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
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow],
                createParticlePath: _drawCircle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 2,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMascotSection(BuildContext context, Color color) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // RADIATING RINGS
            ...List.generate(3, (index) {
              return Container(
                width: (180 + (index * 40)).r,
                height: (180 + (index * 40)).r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: (1.5 + index).seconds,
                    curve: Curves.easeOut,
                  ).fadeOut();
            }),

            // SMART MASCOT
            VowlMascot(
              isKidsMode: true,
              size: 90.r,
              state: widget.isCorrect ? VowlMascotState.happy : VowlMascotState.worried,
              useFloatingAnimation: true,
            ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
          ],
        );
      },
    );
  }

  Path _drawCircle(Size size) {
    final path = Path();
    final double radius = size.width / 2;
    path.addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius));
    return path;
  }
}
