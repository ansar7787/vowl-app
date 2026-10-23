import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Interactive pulsating speaker button to hear connected speech phrases aloud.
class ConnectedSpeechPulseSpeaker extends StatelessWidget {
  /// The sentence or phrase to synthesize via TTS.
  final String text;

  /// Theme accent color.
  final Color color;

  /// Callback executed to trigger TTS playback.
  final Function(String) onPlayTts;

  /// Whether a compact visual style should be rendered.
  final bool isCompact;

  /// Creates a [ConnectedSpeechPulseSpeaker] widget.
  const ConnectedSpeechPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isCompact ? 80.r : 90.r;
    final double iconSize = isCompact ? 22.r : 25.r;
    final bool reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget icon = Icon(Icons.graphic_eq_rounded, color: color, size: iconSize);
    if (!reduceMotion) {
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
      label: 'Hear connected speech phrase',
      child: ScaleButton(
        key: const ValueKey('connected_speech_speaker'),
        onTap: () => onPlayTts(text),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                SizedBox(height: 3.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "HEAR PHRASE",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: color,
                        fontSize: isCompact ? 8.5.sp : 9.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
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
