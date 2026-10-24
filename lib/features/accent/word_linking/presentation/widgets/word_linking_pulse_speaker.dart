import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Animated audio speaker for listening to connected sentence liaison and catenation.
class WordLinkingPulseSpeaker extends StatelessWidget {
  /// Spoken sentence to play via TTS.
  final String text;

  /// Theme accent color.
  final Color color;

  /// Callback executed when the speaker button is pressed.
  final Function(String) onPlayTts;

  /// Creates a [WordLinkingPulseSpeaker] widget.
  const WordLinkingPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final icon = Icon(Icons.volume_up_rounded, color: color, size: 28.r);

    return ScaleButton(
      key: const ValueKey('word_linking_pulse_speaker_btn'),
      onTap: () => onPlayTts(text),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: reduceMotion
                  ? icon
                  : icon
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: const Duration(milliseconds: 900),
                        ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Tap to listen",
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
