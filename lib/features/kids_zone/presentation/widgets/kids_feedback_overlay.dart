import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
    final shadowColor = widget.isCorrect ? const Color(0xFF047857) : const Color(0xFFB91C1C);

    return Positioned.fill(
      child: Stack(
        children: [
          // Semi-transparent dim background
          Container(color: Colors.black.withValues(alpha: 0.6)),

          // CONTENT
          Center(
            child: ScaleButton(
              onTap: widget.onTap,
              child: Container(
                width: 300.w,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(color: Colors.white, width: 8.w),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      offset: Offset(0, 12.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMascotSection(context, shadowColor),
                    SizedBox(height: 24.h),
                    
                    // MAIN TITLE
                    Text(
                      widget.isCorrect ? context.tr('games.kids_awesome') : context.tr('games.kids_oh_no'),
                      style: TextStyle(
                        fontFamily: 'Outfit', 
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(color: shadowColor, offset: const Offset(0, 4), blurRadius: 0),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),

                    SizedBox(height: 16.h),

                    // SUBTITLE
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: shadowColor, width: 3.w),
                        boxShadow: [
                           BoxShadow(color: shadowColor, offset: Offset(0, 4.h))
                        ]
                      ),
                      child: Text(
                        widget.isCorrect 
                          ? context.tr('games.kids_success_msg') 
                          : (widget.attempts >= 2 
                             ? context.tr('games.kids_review_msg') 
                             : context.tr('games.kids_try_again_msg')),
                        style: TextStyle(
                          fontFamily: 'Outfit', 
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),

                    if (!widget.isCorrect) ...[
                      SizedBox(height: 24.h),
                      // STRIKE INDICATOR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (index) {
                          final isUsed = index < widget.attempts;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 8.w),
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: isUsed ? Colors.grey[400] : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isUsed ? Colors.grey[600]! : shadowColor,
                                width: 3.w,
                              ),
                            ),
                            child: Icon(
                              isUsed ? Icons.close_rounded : Icons.favorite_rounded,
                              color: isUsed ? Colors.white : Colors.redAccent,
                              size: 20.sp,
                            ),
                          ).animate(target: isUsed ? 1 : 0).shake(duration: 500.ms).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2));
                        }),
                      ).animate().fadeIn(delay: 600.ms),
                    ],

                    SizedBox(height: 32.h),

                    // MODERN 3D BUTTON
                    Container(
                      width: double.infinity,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32.r),
                        border: Border.all(color: shadowColor, width: 4.w),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            offset: Offset(0, 6.h),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('common.continue_text').toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit', 
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 30.sp),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutBack),

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

  Widget _buildMascotSection(BuildContext context, Color shadowColor) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: shadowColor, width: 6.w),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: VowlMascot(
            isKidsMode: true,
            size: 90.r,
            state: widget.isCorrect ? VowlMascotState.happy : VowlMascotState.worried,
            useFloatingAnimation: true,
          ),
        ).animate().scale(delay: 300.ms, curve: Curves.elasticOut);
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
