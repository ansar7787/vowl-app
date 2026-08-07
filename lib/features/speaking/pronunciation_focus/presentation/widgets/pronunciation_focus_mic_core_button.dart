import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PronunciationFocusMicCoreButton extends StatelessWidget {
  final bool isListening;
  final double timeVal;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final int attempts;
  final bool isAnswered;

  const PronunciationFocusMicCoreButton({
    super.key,
    required this.isListening,
    required this.timeVal,
    required this.primaryColor,
    required this.isDark,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.attempts,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

    return GestureDetector(
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer thermo glow aura ring
              Container(
                    width: 96.r,
                    height: 96.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color: isListening
                            ? Colors.orangeAccent.withValues(alpha: 0.3)
                            : Colors.blueAccent.withValues(alpha: 0.1),
                        width: 4.r,
                      ),
                    ),
                  )
                  .animate(target: isListening ? 1 : 0)
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.15, 1.15),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  ),

              // Inner sizzling button core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isListening
                          ? [Colors.orange[900]!, Colors.orangeAccent]
                          : [const Color(0xFF0F2027), const Color(0xFF203A43)],
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: Colors.orangeAccent.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 25.r,
                              spreadRadius: 2.r,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10.r,
                            ),
                          ],
                  ),
                  child: Icon(
                    isListening
                        ? Icons.local_fire_department_rounded
                        : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            isListening
                ? "RELEASE CORE TO INITIATE FUSION"
                : "HOLD SIZZLE CORE TO RECORD PHONEME ACCENT",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
