import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Foggy interactive mirror obscuring passage text until cleared by rubbing gestures.
class ReadingInferenceFoggyMirror extends StatelessWidget {
  /// The full text of the obscured reading passage.
  final String passage;

  /// Theme accent color applied to mirror borders and highlights.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Whether the question has been answered.
  final bool isAnswered;

  /// Recorded gesture touch points clearing the fog.
  final List<Offset> rubPoints;

  /// Normalized clarity ratio between 0.0 (opaque) and 1.0 (clear).
  final double clarity;

  /// Callback invoked when a pan or touch gesture rubs the mirror surface.
  final Function(Offset) onRub;

  /// Creates a [ReadingInferenceFoggyMirror] widget.
  const ReadingInferenceFoggyMirror({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.rubPoints,
    required this.clarity,
    required this.onRub,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onRub(details.localPosition),
      onTapDown: (details) => onRub(details.localPosition),
      child: Stack(
        children: [
          // Clear Passage Container
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.05 : 0.08),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header inside the passage card
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 15.r,
                      color: color.withValues(alpha: 0.9),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Passage',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: color.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    if (!isAnswered && clarity < 1.0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 11.r,
                              color: color,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${(clarity * 100).toInt()}% clear',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  passage,
                  softWrap: true,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    height: 1.55,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppColors.slate800,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Fog Cover Layer
          if (!isAnswered && clarity < 1.0)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: CustomPaint(
                  painter: FogPainter(
                    points: rubPoints,
                    clarity: clarity,
                    color: isDark
                        ? const Color(0xFF242A38)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),

          // Interactive Swipe Prompt
          if (rubPoints.isEmpty && !isAnswered)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 38.r,
                      color: isDark ? Colors.white70 : Colors.black54,
                    )
                        .animate(
                          onPlay: (c) {
                            if (!VowlMotion.shouldReduceMotion(context)) {
                              c.repeat();
                            }
                          },
                        )
                        .moveX(
                          begin: -30.w,
                          end: 30.w,
                          duration: 1.seconds,
                          curve: Curves.easeInOut,
                        )
                        .fade(begin: 0.3, end: 1.0)
                        .then()
                        .moveX(
                          begin: 30.w,
                          end: -30.w,
                          duration: 1.seconds,
                          curve: Curves.easeInOut,
                        )
                        .fade(begin: 1.0, end: 0.3),
                    SizedBox(height: 6.h),
                    Text(
                      'Swipe to reveal the passage',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FogPainter extends CustomPainter {
  final List<Offset> points;
  final double clarity;
  final Color color;

  FogPainter({
    required this.points,
    required this.clarity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 36.r
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 18.r, clearPaint);
      if (i < points.length - 1) {
        final dist = (points[i] - points[i + 1]).distance;
        if (dist < 80.r) {
          canvas.drawLine(points[i], points[i + 1], clearPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.clarity != clarity ||
        oldDelegate.color != color;
  }
}
