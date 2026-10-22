import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';

class MinimalPairsSpeakerCore extends StatelessWidget {
  final String text;
  final Color color;
  final Function(String) onPlayTts;

  const MinimalPairsSpeakerCore({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget coreContainer = Container(
      width: 84.r,
      height: 84.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        border: Border.all(color: color, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.25 : 0.18),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volume_up_rounded,
              color: color,
              size: 28.r,
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('games.tap_to_listen', fallback: 'Tap to listen'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      coreContainer = coreContainer
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 1.5.seconds,
          );
    }

    return Semantics(
      button: true,
      label: context.tr('games.play_audio', fallback: 'Play audio'),
      excludeSemantics: true,
      child: ScaleButton(
        key: const ValueKey('minimal_pairs_speaker_btn'),
        onTap: () => onPlayTts(text),
        child: coreContainer,
      ),
    );
  }
}
