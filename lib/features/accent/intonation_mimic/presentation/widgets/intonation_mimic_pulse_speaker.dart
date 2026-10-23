import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Animated pulsing audio button for previewing expressive pitch contours.
class IntonationMimicPulseSpeaker extends StatelessWidget {
  /// The phrase to vocalize with intonation.
  final String text;

  /// Theme accent color.
  final Color color;

  /// Callback executed when the speaker button is pressed.
  final Function(String) onPlayTts;

  /// Creates an [IntonationMimicPulseSpeaker] widget.
  const IntonationMimicPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget speakerIcon = Icon(
      Icons.graphic_eq_rounded,
      color: color,
      size: 26.r,
    );

    if (!reduceMotion) {
      speakerIcon = speakerIcon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.12, 1.12),
          );
    }

    return ScaleButton(
      key: const ValueKey('intonation_speaker_btn'),
      onTap: () => onPlayTts(text),
      child: Container(
        width: 80.r,
        height: 80.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  speakerIcon,
                  SizedBox(height: 3.h),
                  Text(
                    "Listen",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: color,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
