import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Pulsating audio speaker synthesizing speed variance phrases via TTS.
class SpeedVariancePulseSpeaker extends StatelessWidget {
  /// Spoken text to vocalize via TTS.
  final String text;

  /// Theme accent color.
  final Color color;

  /// Callback executed when the speaker button is pressed.
  final Function(String) onPlayTts;

  /// Creates a [SpeedVariancePulseSpeaker] widget.
  const SpeedVariancePulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final shouldReduce = VowlMotion.shouldReduceMotion(context);
    Widget icon = Icon(Icons.graphic_eq_rounded, color: color, size: 26.r);
    if (!shouldReduce) {
      icon = icon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.15, 1.15),
            duration: 800.ms,
          );
    }

    return Semantics(
      button: true,
      label: 'Listen to phrase',
      child: ScaleButton(
        key: const ValueKey('speed_variance_pulse_speaker'),
        onTap: () => onPlayTts(text),
        child: Container(
          width: 78.r,
          height: 78.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                SizedBox(height: 4.h),
                Text(
                  "Listen",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
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
