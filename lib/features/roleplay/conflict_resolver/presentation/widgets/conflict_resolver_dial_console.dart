import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_equalizer_painter.dart';

class ConflictResolverDialConsole extends StatelessWidget {
  final double targetValue;
  final Color color;
  final bool isDark;
  final double rotation;
  final Animation<double> waveAnimation;
  final Function(DragUpdateDetails, Offset) onDialDragged;

  const ConflictResolverDialConsole({
    super.key,
    required this.targetValue,
    required this.color,
    required this.isDark,
    required this.rotation,
    required this.waveAnimation,
    required this.onDialDragged,
  });

  @override
  Widget build(BuildContext context) {
    final double dialDiameter = 220.r;
    final Offset dialCenter = Offset(dialDiameter / 2, dialDiameter / 2);
    final bool isMatched = (rotation - targetValue).abs() < 0.12;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF07070F)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        children: [
          // Holographic Dial Board
          GestureDetector(
            onPanUpdate: (details) => onDialDragged(details, dialCenter),
            child: Container(
              width: dialDiameter,
              height: dialDiameter,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning audio spectrum equalizer lines
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: EqualizerArcPainter(
                            rotationValue: rotation,
                            targetValue: targetValue,
                            timeAnimation: waveAnimation.value,
                            themeColor: color,
                          ),
                        );
                      },
                    ),
                  ),

                  // Metallic rotatable core knob
                  Transform.rotate(
                    angle: rotation * 2 * math.pi,
                    child: Container(
                      width: 130.r,
                      height: 130.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF2A2A3E),
                                  const Color(0xFF131326),
                                ]
                              : [Colors.white, Colors.grey.shade300],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(3, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isMatched
                              ? Colors.greenAccent
                              : color.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotary position notch marker
                          Positioned(
                            top: 8.r,
                            child: Container(
                              width: 6.r,
                              height: 16.r,
                              decoration: BoxDecoration(
                                color: isMatched ? Colors.greenAccent : color,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ),
                          Icon(
                            isMatched
                                ? Icons.check_rounded
                                : Icons.tune_rounded,
                            color: isMatched
                                ? Colors.greenAccent
                                : color.withValues(alpha: 0.7),
                            size: 32.r,
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

          // Calibration level metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "DIAL LEVEL: ",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10.sp,
                  color: Colors.grey,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "${(rotation * 100).toInt()}% empathy",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: isMatched
                      ? Colors.greenAccent
                      : Color.lerp(
                          Colors.cyanAccent,
                          Colors.redAccent,
                          rotation,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
