import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Speaker node triggering audio playback of emotionally colored spoken dialogue.
class EmotionRecognitionEmitter extends StatelessWidget {
  /// Callback triggered when the emitter is tapped.
  final VoidCallback onTap;

  /// Theme accent color.
  final Color color;

  /// Optional celebratory emoji revealed upon correct emotion classification.
  final String? emoji;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Creates an [EmotionRecognitionEmitter] widget.
  const EmotionRecognitionEmitter({
    super.key,
    required this.onTap,
    required this.color,
    this.emoji,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Semantics(
      label: 'Play audio voice',
      button: true,
      excludeSemantics: true,
      child: ScaleButton(
        key: const Key('emotion_recognition_emitter_btn'),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border: Border.all(
                  color: color.withValues(alpha: 0.28),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isCorrectState == true && emoji != null
                  ? (reduceMotion
                      ? Text(
                          emoji!,
                          key: const Key('emotion_recognition_emoji'),
                          style: TextStyle(fontSize: 38.sp),
                        )
                      : Text(
                          emoji!,
                          key: const Key('emotion_recognition_emoji'),
                          style: TextStyle(fontSize: 38.sp),
                        )
                          .animate()
                          .scale(duration: 400.ms, curve: Curves.easeOutCubic))
                  : (reduceMotion
                      ? Icon(
                          Icons.volume_up_rounded,
                          color: color,
                          size: 38.r,
                        )
                      : Icon(
                          Icons.volume_up_rounded,
                          color: color,
                          size: 38.r,
                        )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.08, 1.08),
                            duration: 1.seconds,
                          )),
            ),
            if (isCorrectState != true) ...[
              SizedBox(height: 10.h),
              reduceMotion
                  ? Text(
                      'Tap to listen',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.85),
                        letterSpacing: 0.2,
                      ),
                    )
                  : Text(
                      'Tap to listen',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.85),
                        letterSpacing: 0.2,
                      ),
                    )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .fade(begin: 0.65, end: 1.0, duration: 1.seconds),
            ],
          ],
        ),
      ),
    );
  }
}
