import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SituationSpeakingScrubbedMicTrigger extends StatelessWidget {
  final bool isListening;
  final double scrubProgress;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const SituationSpeakingScrubbedMicTrigger({
    super.key,
    required this.isListening,
    required this.scrubProgress,
    required this.primaryColor,
    required this.isDark,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = scrubProgress >= 0.95;

    return GestureDetector(
      onLongPressStart: (_) => isEnabled ? onLongPressStart() : null,
      onLongPressEnd: (_) => isEnabled ? onLongPressEnd() : null,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Beautiful condensation ring pulses
              if (isListening)
                ...List.generate(4, (i) {
                  return Container(
                    width: 76.r + (i * 24.r),
                    height: 76.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        width: 1.5.r,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1.0, 1.0), 
                    end: const Offset(1.15, 1.15), 
                    duration: const Duration(milliseconds: 800), 
                    curve: Curves.easeOut
                  )
                  .fadeOut();
                }),

              // Outer boundary ring
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: isEnabled
                        ? (isListening
                            ? Colors.cyanAccent.withValues(alpha: 0.35)
                            : primaryColor.withValues(alpha: 0.15))
                        : Colors.grey.withValues(alpha: 0.1),
                    width: 4.r,
                  ),
                ),
              ).animate(target: isListening ? 1 : 0).scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  ),

              // Interactive Mic Core
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isEnabled
                          ? (isListening
                              ? [Colors.teal[900]!, Colors.cyanAccent]
                              : [const Color(0xFF1F1C2C), const Color(0xFF928DAB)])
                          : [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.45),
                              blurRadius: 25.r,
                              spreadRadius: 2.r,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10.r,
                            )
                          ],
                  ),
                  child: Icon(
                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            !isEnabled
                ? "WIPE SCREEN TO UNLOCK VOCAL PORT"
                : (isListening
                    ? "RELEASE MICROPHONE TO SUBMIT ANSWER"
                    : "HOLD MICROPHONE TO RESPOND TO SCENE"),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'RobotoMono', 
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
