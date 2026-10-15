import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class AudioTrueFalseTuner extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final AnimationController audioController;

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
                    width: 80.r,
                    height: 80.r,
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
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 32.r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
