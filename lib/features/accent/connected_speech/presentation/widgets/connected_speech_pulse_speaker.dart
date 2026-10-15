import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ConnectedSpeechPulseSpeaker extends StatelessWidget {
  final String text;
  final Color color;
  final Function(String) onPlayTts;
  const ConnectedSpeechPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = 100.r;
    final double iconSize = 32.r;
    final bool reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget icon = Icon(Icons.graphic_eq_rounded, color: color, size: iconSize);
    if (!reduceMotion) {
      icon = icon
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
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
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                SizedBox(height: 6.h),
                Text(
                  "HEAR PHRASE",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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
