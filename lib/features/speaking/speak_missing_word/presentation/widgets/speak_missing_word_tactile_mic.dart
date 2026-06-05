import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SpeakMissingWordTactileMic extends StatelessWidget {
  final bool isSpeechActive;
  final Color primaryColor;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const SpeakMissingWordTactileMic({
    super.key,
    required this.isSpeechActive,
    required this.primaryColor,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => onLongPressStart(),
          onLongPressEnd: (_) => onLongPressEnd(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSpeechActive)
                ...List.generate(
                  3,
                  (i) => Container(
                    width: 90.r + (i * 24.r),
                    height: 90.r + (i * 24.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                        duration: const Duration(seconds: 1),
                      ).fadeOut(),
                ),
              ScaleButton(
                onTap: () {},
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isSpeechActive
                          ? [primaryColor, primaryColor.withValues(alpha: 0.7)]
                          : [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                    boxShadow: isSpeechActive
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 18,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    isSpeechActive ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 32.r,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          isSpeechActive ? "RELEASE LENS TO PROCESS SENTENCE" : "HOLD LENS TO RECORD FULL COMPLETED SENTENCE",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'RobotoMono', 
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
