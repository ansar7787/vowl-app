import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SoundImageMatchEmitter extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final String? emoji;
  final bool? isCorrectState;

  const SoundImageMatchEmitter({
    super.key,
    required this.onTap,
    required this.color,
    this.emoji,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      scaleDown: 0.9,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: -10,
              offset: const Offset(-5, -5),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 2,
          ),
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.05),
              color.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: isCorrectState == true && emoji != null
            ? Text(
                emoji!,
                style: TextStyle(fontSize: 52.r),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
            : Icon(Icons.volume_up_rounded, color: color, size: 52.r)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 2.seconds,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
      ),
    );
  }
}
