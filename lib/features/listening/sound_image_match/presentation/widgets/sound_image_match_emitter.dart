import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Speaker node triggering audio or sound effect playback for image matching.
class SoundImageMatchEmitter extends StatelessWidget {
  /// Callback triggered when the emitter is tapped.
  final VoidCallback onTap;

  /// Theme accent color.
  final Color color;

  /// Optional celebratory emoji revealed upon correct choice.
  final String? emoji;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Creates a [SoundImageMatchEmitter] widget.
  const SoundImageMatchEmitter({
    super.key,
    required this.onTap,
    required this.color,
    this.emoji,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Play sound',
      button: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScaleButton(
            key: const Key('sound_image_match_emitter_btn'),
            onTap: onTap,
            scaleDown: 0.92,
            child: Container(
              width: 88.r,
              height: 88.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.25 : 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.4 : 0.3),
                  width: 1.8,
                ),
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.05),
                    color.withValues(alpha: 0.18),
                  ],
                ),
              ),
              child: Center(
                child: isCorrectState == true && emoji != null
                    ? (reduceMotion
                        ? Text(
                            emoji!,
                            key: const Key('sound_image_match_emitter_emoji'),
                            style: TextStyle(fontSize: 44.r),
                          )
                        : Text(
                            emoji!,
                            key: const Key('sound_image_match_emitter_emoji'),
                            style: TextStyle(fontSize: 44.r),
                          )
                            .animate()
                            .scale(duration: 400.ms, curve: Curves.easeOutCubic))
                    : (reduceMotion
                        ? Icon(
                            Icons.volume_up_rounded,
                            key: const Key('sound_image_match_emitter_icon'),
                            color: color,
                            size: 44.r,
                          )
                        : Icon(
                            Icons.volume_up_rounded,
                            key: const Key('sound_image_match_emitter_icon'),
                            color: color,
                            size: 44.r,
                          )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(
                              duration: 2.seconds,
                              color: Colors.white.withValues(alpha: 0.6),
                            )),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            isCorrectState == true ? 'Great match!' : 'Tap to listen',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : color.withValues(alpha: 0.85),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
