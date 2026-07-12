import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SpeakMissingWordTactileMic extends StatelessWidget {
  final bool isSpeechActive;
  final Color primaryColor;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final int attempts;
  final bool isAnswered;
  final VoidCallback onTutorPass;

  const SpeakMissingWordTactileMic({
    super.key,
    required this.isSpeechActive,
    required this.primaryColor,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.attempts,
    required this.isAnswered,
    required this.onTutorPass,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

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
                  (i) =>
                      Container(
                            width: 90.r + (i * 24.r),
                            height: 90.r + (i * 24.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.3, 1.3),
                            duration: const Duration(seconds: 1),
                          )
                          .fadeOut(),
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
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isSpeechActive
                        ? Icons.graphic_eq_rounded
                        : Icons.mic_none_rounded,
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
          isSpeechActive
              ? "RELEASE LENS TO PROCESS SENTENCE"
              : "HOLD LENS TO RECORD FULL COMPLETED SENTENCE",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9.sp,
            color: Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
        if (attempts > 0 && !isSpeechActive)
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Semantics(
              button: true,
              hint: context.tr('games.semantic_tutor_pass_hint'),
              child: ScaleButton(
                onTap: onTutorPass,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.amber,
                            size: 18.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            context.tr('games.i_spoke_correctly').toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.amber,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().shake(),
      ],
    );
  }
}
