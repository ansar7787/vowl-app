import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PitchPatternMatchMelodicCanvas extends StatelessWidget {
  final List<int> pattern;
  final Color color;
  final bool isDark;
  final bool isPreviewing;
  final bool isAnswered;
  final double previewProgress;

  const PitchPatternMatchMelodicCanvas({
    super.key,
    required this.pattern,
    required this.color,
    required this.isDark,
    required this.isPreviewing,
    required this.isAnswered,
    required this.previewProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
      ),
      child: Stack(
        children: [
          // Blueprint
          Center(
            child: CustomPaint(
              size: Size(0.7.sw, 100.h),
              painter: _BlueprintPainter(pattern, color.withValues(alpha: 0.2)),
            ),
          ),
          // User Ink/Glow Progress
          if (isPreviewing || isAnswered)
            Center(
              child: CustomPaint(
                size: Size(0.7.sw, 100.h),
                painter: _BlueprintPainter(pattern, color, progress: isPreviewing ? previewProgress : 1.0),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  final List<int> pattern;
  final Color color;
  final double progress;
  _BlueprintPainter(this.pattern, this.color, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    if (pattern.isEmpty) return;

    double dx = size.width / (pattern.length - 1);
    path.moveTo(0, size.height - (pattern[0] / 4.0 * size.height));

    for (int i = 1; i < pattern.length; i++) {
      if (i / (pattern.length - 1) > progress) break;
      path.lineTo(i * dx, size.height - (pattern[i] / 4.0 * size.height));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
