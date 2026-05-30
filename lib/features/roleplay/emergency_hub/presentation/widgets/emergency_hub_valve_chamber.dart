import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/roleplay/emergency_hub/presentation/widgets/emergency_hub_valve_painter.dart';

class EmergencyHubValveChamber extends StatelessWidget {
  final String correctAnswer;
  final String inputText;
  final bool isDark;
  final double rotation;
  final Animation<double> pulseAnimation;
  final Function(DragUpdateDetails, Offset) onValveDragged;

  const EmergencyHubValveChamber({
    super.key,
    required this.correctAnswer,
    required this.inputText,
    required this.isDark,
    required this.rotation,
    required this.pulseAnimation,
    required this.onValveDragged,
  });

  @override
  Widget build(BuildContext context) {
    final double size = 200.r;
    final Offset center = Offset(size / 2, size / 2);
    
    final bool isCodeValid = inputText.trim().replaceAll(' ', '').toLowerCase() ==
        correctAnswer.trim().replaceAll(' ', '').toLowerCase();
    
    final bool isValveAligned = rotation >= 0.85;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onPanUpdate: (details) => onValveDragged(details, center),
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hazard stripes warning outer sweep ring
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: EmergencyValvePainter(
                            rotationValue: rotation,
                            isCodeCorrect: isCodeValid,
                            animationTime: pulseAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // Heavy metal wheel knob
                  Transform.rotate(
                    angle: rotation * 2 * math.pi,
                    child: Container(
                      width: 120.r,
                      height: 120.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade900,
                        border: Border.all(
                          color: isValveAligned ? Colors.greenAccent : Colors.redAccent,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Spokes
                          for (int i = 0; i < 3; i++)
                            Transform.rotate(
                              angle: i * 2 * math.pi / 3,
                              child: Container(
                                width: 8.w,
                                height: 96.h,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          
                          // Centre locking warning lens
                          Container(
                            width: 50.r,
                            height: 50.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isValveAligned ? Colors.greenAccent : Colors.redAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: (isValveAligned ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              isValveAligned ? Icons.lock_open_rounded : Icons.lock_rounded,
                              color: Colors.white,
                              size: 24.r,
                            ),
                          ),

                          // Indicator needle notch
                          Positioned(
                            top: 6.r,
                            child: Icon(
                              Icons.arrow_drop_up_rounded,
                              color: isValveAligned ? Colors.greenAccent : Colors.white70,
                              size: 24.r,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Valve status indicators text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "VALVE LEVEL: ",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                isValveAligned ? "ALIGNED (READY)" : "LOCK PENDING (TURN TO 90%)",
                style: GoogleFonts.shareTechMono(
                  fontSize: 11.sp,
                  color: isValveAligned ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
