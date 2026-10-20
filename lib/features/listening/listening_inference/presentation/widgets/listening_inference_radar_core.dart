import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ListeningInferenceRadarCore extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController pulseController;
  final Color color;
  final String? emoji;
  final bool? isCorrectState;

  const ListeningInferenceRadarCore({
    super.key,
    required this.onTap,
    required this.pulseController,
    required this.color,
    this.emoji,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Semantics(
      label: 'Play audio inference',
      button: true,
      excludeSemantics: true,
      child: ScaleButton(
        key: const Key('listening_inference_radar_btn'),
        onTap: onTap,
        child: SizedBox(
          width: 140.r,
          height: 140.r,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Rings
              if (!reduceMotion)
                ...List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      double progress =
                          (pulseController.value + (i * 0.33)) % 1.0;
                      return Container(
                        width: (72 + (progress * 60)).r,
                        height: (72 + (progress * 60)).r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withValues(
                              alpha: (1.0 - progress) * 0.28,
                            ),
                            width: 1.5.r,
                          ),
                        ),
                      );
                    },
                  );
                }),

              // Central Core
              Container(
                width: 78.r,
                height: 78.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color, color.withValues(alpha: 0.85)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isCorrectState == true && emoji != null
                    ? (reduceMotion
                        ? Text(
                            emoji!,
                            key: const Key('listening_inference_emoji'),
                            style: TextStyle(fontSize: 38.sp),
                          )
                        : Text(
                            emoji!,
                            key: const Key('listening_inference_emoji'),
                            style: TextStyle(fontSize: 38.sp),
                          )
                            .animate()
                            .scale(duration: 400.ms, curve: Curves.easeOutCubic))
                    : Icon(
                        Icons.psychology_rounded,
                        size: 38.r,
                        color: Colors.white,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
