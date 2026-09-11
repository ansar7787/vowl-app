import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AudioTrueFalseTuner extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final AnimationController audioController;
  final String? emoji;

  const AudioTrueFalseTuner({
    super.key,
    required this.onTap,
    required this.color,
    required this.audioController,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: audioController,
              builder: (_, _) {
                if (!audioController.isAnimating &&
                    audioController.value == 0) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  width: 56.r,
                  height: 56.r,
                  child: CircularProgressIndicator(
                    value: audioController.value,
                    strokeWidth: 4,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
            if (emoji != null && emoji!.isNotEmpty)
              Text(emoji!, style: TextStyle(fontSize: 40.sp))
            else
              Icon(Icons.graphic_eq_rounded, color: color, size: 48.r),
          ],
        ),
      ),
    );
  }
}
