import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShadowWaveformVisualizer extends StatelessWidget {
  final ValueNotifier<double> soundLevel;
  final Color color;

  const ShadowWaveformVisualizer({
    super.key,
    required this.soundLevel,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: soundLevel,
      builder: (context, normalized, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final baseModifier = const [0.4, 0.8, 1.0, 0.8, 0.4][index];
            // Add slight organic jitter when the user is speaking to simulate frequency variance
            final jitter = normalized > 0.05
                ? (math.Random().nextDouble() * 0.3 - 0.15)
                : 0.0;
            final modifier = (baseModifier + jitter).clamp(0.1, 1.2);

            final targetHeight = 12.h + (36.h * normalized * modifier);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutQuad,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: 4.w,
              height: targetHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        );
      },
    );
  }
}
