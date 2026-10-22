import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class PitchModulationPulseSpeaker extends StatelessWidget {
  final String text;
  final Color color;
  final Function(String) onPlayTts;

  const PitchModulationPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: "Tap to listen to $text",
      child: ScaleButton(
        key: const ValueKey('pitch_modulation_speaker_btn'),
        onTap: () => onPlayTts(text),
        child: Container(
          width: 88.r,
          height: 88.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    final reduceMotion = VowlMotion.shouldReduceMotion(context);
                    Widget icon = Icon(
                      Icons.volume_up_rounded,
                      color: color,
                      size: 30.r,
                    );
                    if (!reduceMotion) {
                      icon = icon
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.15, 1.15),
                            duration: 800.ms,
                          );
                    }
                    return icon;
                  },
                ),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    "Tap to listen",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: color,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
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
