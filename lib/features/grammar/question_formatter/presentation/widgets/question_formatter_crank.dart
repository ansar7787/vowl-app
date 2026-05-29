import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuestionFormatterCrank extends StatelessWidget {
  final double crankRotation;
  final bool isAnswered;
  final bool isDark;
  final Color primaryColor;
  final ValueChanged<double> onPanUpdate;
  final VoidCallback onAutoSpin;

  const QuestionFormatterCrank({
    super.key,
    required this.crankRotation,
    required this.isAnswered,
    required this.isDark,
    required this.primaryColor,
    required this.onPanUpdate,
    required this.onAutoSpin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (isAnswered) return;
        onPanUpdate(details.delta.dx + details.delta.dy);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Energy Ring
          Container(
            width: 180.r,
            height: 180.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),

          // The Mechanical Crank
          Container(
            width: 140.r,
            height: 140.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 6.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: crankRotation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Mechanical Arm
                      Column(
                        children: [
                          Container(
                            width: 14.r,
                            height: 45.r,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      // Gear Teeth
                      ...List.generate(
                        8,
                        (i) => Transform.rotate(
                          angle: i * (pi / 4),
                          child: Column(
                            children: [
                              Container(
                                width: 4.r,
                                height: 10.r,
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onAutoSpin,
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: primaryColor,
                      size: 36.r,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
