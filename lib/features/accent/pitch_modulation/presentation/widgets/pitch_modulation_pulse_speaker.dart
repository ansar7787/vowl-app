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
    return ScaleButton(
      key: const ValueKey('pitch_modulation_speaker_btn'),
      onTap: () => onPlayTts(text),
      child: Container(
        width: 96.r,
        height: 96.r,
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
              Builder(
                builder: (context) {
                  final reduceMotion = VowlMotion.shouldReduceMotion(context);
                  Widget icon = Icon(
                    Icons.graphic_eq_rounded,
                    color: color,
                    size: 28.r,
                  );
                  if (!reduceMotion) {
                    icon = icon
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                        );
                  }
                  return icon;
                },
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "HEAR\nMODULATION",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: color,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
