import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class SyllableStressPulseSpeaker extends StatelessWidget {
  final String text;
  final Color color;
  final Function(String) onPlayTts;

  const SyllableStressPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final icon = Icon(Icons.graphic_eq_rounded, color: color, size: 28.r);

    return Semantics(
      button: true,
      label: 'Listen to syllable stress',
      child: ScaleButton(
        key: const ValueKey('syllable_stress_pulse_speaker_btn'),
        onTap: () => onPlayTts(text),
        child: Container(
          width: 92.r,
          height: 92.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                reduceMotion
                    ? icon
                    : icon
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                          duration: 1.seconds,
                        ),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "HEAR STRESS",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: color,
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
