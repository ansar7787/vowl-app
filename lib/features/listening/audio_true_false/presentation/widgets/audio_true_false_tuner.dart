import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Audio tuner playback button with an animated circular progress indicator.
class AudioTrueFalseTuner extends StatelessWidget {
  /// Callback triggered when the tuner is tapped.
  final VoidCallback onTap;

  /// Theme accent color.
  final Color color;

  /// Animation controller driving the circular audio progress ring.
  final AnimationController audioController;

  /// Creates an [AudioTrueFalseTuner] instance.
  const AudioTrueFalseTuner({
    super.key,
    required this.onTap,
    required this.color,
    required this.audioController,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Semantics(
      label: 'Play audio statement',
      hint: 'Double tap to hear the statement',
      button: true,
      child: ScaleButton(
        key: const Key('audio_true_false_tuner_btn'),
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!reduceMotion)
              AnimatedBuilder(
                animation: audioController,
                builder: (_, _) {
                  if (!audioController.isAnimating && audioController.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: 76.r,
                    height: 76.r,
                    child: CircularProgressIndicator(
                      value: audioController.value,
                      strokeWidth: 3,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  );
                },
              ),
            Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 28.r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
