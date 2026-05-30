import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class RepeatSentenceTactileMic extends StatelessWidget {
  final bool isListening;
  final Color primaryColor;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const RepeatSentenceTactileMic({
    super.key,
    required this.isListening,
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
              if (isListening)
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
                      colors: isListening
                          ? [primaryColor, primaryColor.withValues(alpha: 0.7)]
                          : [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 18,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
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
          isListening ? "RELEASE LENS TO PROCESS PHONEMES" : "HOLD LENS TO RECORD YOUR SPEECH",
          style: GoogleFonts.shareTechMono(
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
