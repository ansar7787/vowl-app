import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AudioSentenceOrderOscilloscope extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const AudioSentenceOrderOscilloscope({
    super.key,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        height: 100.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(
              20,
              (i) => Container(
                width: 4.w,
                height: 20.h + (i % 5 * 10).h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleY(
                begin: 0.5,
                end: 1.5,
                duration: 500.ms,
                delay: (i * 50).ms,
              ),
            ),
            Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 48.r),
          ],
        ),
      ),
    );
  }
}
