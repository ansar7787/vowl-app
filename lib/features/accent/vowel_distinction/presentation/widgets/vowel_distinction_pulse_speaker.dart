import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Pulsating audio speaker synthesizing acoustic vowel targets via TTS.
class VowelDistinctionPulseSpeaker extends StatelessWidget {
  /// Target word or vowel phoneme to vocalize.
  final String text;

  /// Theme accent color.
  final Color color;

  /// Callback executed when the speaker button is pressed.
  final Function(String) onPlayTts;

  /// Creates a [VowelDistinctionPulseSpeaker] widget.
  const VowelDistinctionPulseSpeaker({
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
      label: 'Listen to vowel sound',
      child: ScaleButton(
        key: const ValueKey('vowel_distinction_pulse_speaker_btn'),
        onTap: () => onPlayTts(text),
        child: Container(
          width: 96.r,
          height: 96.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 16,
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
                        ),
                SizedBox(height: 6.h),
                Text(
                  "HEAR VOWEL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
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
