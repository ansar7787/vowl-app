import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ConnectedSpeechPulseSpeaker extends StatelessWidget {
  final String text;
  final Color color;
  final Function(String) onPlayTts;
  final bool isCompact;

  const ConnectedSpeechPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isCompact ? 76.r : 84.r;
    final double iconSize = isCompact ? 26.r : 28.r;
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 16,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                SizedBox(height: 4.h),
                Text(
                  "HEAR PHRASE",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontSize: isCompact ? 9.sp : 10.sp,
                    fontWeight: FontWeight.w700,
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
