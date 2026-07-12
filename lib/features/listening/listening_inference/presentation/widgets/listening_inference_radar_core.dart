import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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
    return ScaleButton(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Rings
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                double progress = (pulseController.value + (i * 0.33)) % 1.0;
                return Container(
                  width: (100 + (progress * 150)).r,
                  height: (100 + (progress * 150)).r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: (1.0 - progress) * 0.3),
                      width: 2.r,
                    ),
                  ),
                );
              },
            );
          }),

          // Central Core
          Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: isCorrectState == true && emoji != null
                ? Text(
                    emoji!,
                    style: TextStyle(fontSize: 64.r),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
                : Icon(
                    Icons.psychology_rounded,
                    size: 64.r,
                    color: Colors.white,
                  ),
          ),
        ],
      ),
    );
  }
}
