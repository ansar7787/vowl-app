import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class AudioSentenceOrderOscilloscope extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final String? emoji;
  final bool? isCorrectState;

  const AudioSentenceOrderOscilloscope({
    super.key,
    required this.onTap,
    required this.color,
    this.emoji,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final cardBgColor = isDark
        ? const Color(0xFF161626)
        : Colors.white;
    final hintTextColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.65);

    return Semantics(
      label: 'Play sentence audio. Tap to listen.',
      hint: 'Tap to hear the speaker',
      button: true,
      excludeSemantics: true,
      child: ScaleButton(
        key: const Key('audio_sentence_order_oscilloscope_btn'),
        onTap: onTap,
        child: Container(
          height: 104.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.25 : 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Waveform bars in the background
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      22,
                      (i) {
                        final bar = Container(
                          width: 3.5.w,
                          height: 16.h + (i % 6 * 7).h,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.22 : 0.14),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        );
                        if (reduceMotion) return bar;
                        return bar
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleY(
                              begin: 0.4,
                              end: 1.4,
                              duration: 550.ms,
                              delay: (i * 45).ms,
                            );
                      },
                    ),
                  ),
                ),
              ),

              // Foreground content
              if (isCorrectState == true && emoji != null)
                (reduceMotion
                    ? Text(emoji!, style: TextStyle(fontSize: 48.r))
                    : Text(emoji!, style: TextStyle(fontSize: 48.r))
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutCubic))
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: color,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Tap to listen',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: hintTextColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
