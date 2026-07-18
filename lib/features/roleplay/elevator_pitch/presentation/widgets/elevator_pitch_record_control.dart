import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ElevatorPitchRecordControl extends StatelessWidget {
  final bool isListening;
  final Color color;
  final String correctAnswer;
  final VoidCallback onStartListening;
  final Function(String) onStopListening;
  final int attempts;
  final bool isAnswered;

  const ElevatorPitchRecordControl({
    super.key,
    required this.isListening,
    required this.color,
    required this.correctAnswer,
    required this.onStartListening,
    required this.onStopListening,
    required this.attempts,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => onStartListening(),
          onLongPressEnd: (_) => onStopListening(correctAnswer),
          child: ScaleButton(
            onTap: () {},
            child:
                Container(
                      width: 90.r,
                      height: 90.r,
                      decoration: BoxDecoration(
                        color: isListening ? Colors.redAccent : color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isListening ? Colors.redAccent : color)
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 40.r,
                        ),
                      ),
                    )
                    .animate(target: isListening ? 1.0 : 0.0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 1.seconds,
                      curve: Curves.easeInOut,
                    ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          isListening
              ? "RELEASE TO ANALYZE LIFT PITCH"
              : "HOLD LENS TO RECORD PITCH & TAP SHAFT TO BOOST",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
