import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Animated pulse speaker button for listening to reference shadowing audio.
class ShadowingChallengePulseSpeaker extends StatelessWidget {
  /// Reference speech text to play via TTS.
  final String text;

  /// Theme accent color.
  final Color color;

  /// Callback executed when tapping the speaker button.
  final Function(String) onPlayTts;

  /// Creates a [ShadowingChallengePulseSpeaker] widget.
  const ShadowingChallengePulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget icon = Icon(Icons.volume_up_rounded, color: color, size: 26.r);
    if (!reduceMotion) {
      icon = icon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.15, 1.15),
            duration: const Duration(milliseconds: 700),
          );
    }

    return ScaleButton(
      key: const ValueKey('shadowing_speaker_btn'),
      onTap: () => onPlayTts(text),
      child: Container(
        width: 76.r,
        height: 76.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(height: 4.h),
              Text(
                "Listen",
                textAlign: TextAlign.center,
                softWrap: false,
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
    );
  }
}
