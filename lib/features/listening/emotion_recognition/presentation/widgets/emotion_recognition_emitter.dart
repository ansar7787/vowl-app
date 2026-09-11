import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class EmotionRecognitionEmitter extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final String? emoji;
  final bool? isCorrectState;

  const EmotionRecognitionEmitter({
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: isCorrectState == true && emoji != null
                ? Text(
                    emoji!,
                    style: TextStyle(fontSize: 40.r),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
                : Icon(Icons.volume_up_rounded, color: color, size: 40.r)
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1.seconds,
                      ),
          ),
          if (isCorrectState != true) ...[
            SizedBox(height: 12.h),
            Text(
                  "TAP TO LISTEN",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: color.withValues(alpha: 0.8),
                    letterSpacing: 1.5,
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fade(begin: 0.6, end: 1.0, duration: 1.seconds),
          ],
        ],
      ),
    );
  }
}
