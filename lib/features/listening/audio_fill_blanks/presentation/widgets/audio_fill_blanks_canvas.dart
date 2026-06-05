import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class AudioFillBlanksCanvas extends StatelessWidget {
  final String text;
  final double revealProgress;
  final Function(double) onSmear;
  final Color primaryColor;
  final bool isDark;

  const AudioFillBlanksCanvas({
    super.key,
    required this.text,
    required this.revealProgress,
    required this.onSmear,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final delta = details.delta.dx.abs() / 200 + details.delta.dy.abs() / 200;
        onSmear(delta);
      },
      child: GlassTile(
        padding: EdgeInsets.all(32.r),
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: revealProgress,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 20.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            if (revealProgress < 1.0)
              ...List.generate(5, (i) {
                final baseColor = isDark
                    ? Colors.indigo[900]!.withValues(alpha: (0.8 - revealProgress).clamp(0.0, 1.0))
                    : Colors.black87.withValues(alpha: (0.8 - revealProgress).clamp(0.0, 1.0));
                return Positioned(
                  left: 20.w + (i * 50.w),
                  child: Container(
                    width: 60.r,
                    height: 60.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: baseColor,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 2.seconds,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
