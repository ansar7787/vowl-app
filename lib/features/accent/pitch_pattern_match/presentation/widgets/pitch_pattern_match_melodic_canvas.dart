import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Blueprint canvas rendering visual wave representations of target melodic pitch contours.
class PitchPatternMatchMelodicCanvas extends StatelessWidget {
  /// Sequence of pitch level points representing melody elevation.
  final List<int> pattern;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether the animated audio wave preview is actively rendering.
  final bool isPreviewing;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Normalized audio wave progress (0.0 to 1.0).
  final double previewProgress;

  /// Creates a [PitchPatternMatchMelodicCanvas] widget.
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
      constraints: BoxConstraints(maxWidth: 420.w),
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1.2,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              // Baseline contour
              Center(
                child: CustomPaint(
                  size: canvasSize,
                  painter: _BlueprintPainter(
                    pattern,
                    color.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // User / Audio Wave Progress
              if (isPreviewing || isAnswered)
                Center(
                  child: CustomPaint(
                    size: canvasSize,
                    painter: _BlueprintPainter(
                      pattern,
                      color,
                      progress: isPreviewing ? previewProgress : 1.0,
                    ),
                  ),
                ),
            ],
          );
        },
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
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (pattern.isEmpty) return;

    if (pattern.length == 1) {
      final y = size.height - (pattern[0] / 4.0 * size.height);
      path.moveTo(0, y);
      path.lineTo(size.width * progress, y);
      canvas.drawPath(path, paint);
      return;
    }

    double dx = size.width / (pattern.length - 1);
    path.moveTo(0, size.height - (pattern[0] / 4.0 * size.height));

    for (int i = 1; i < pattern.length; i++) {
      double sectionStart = (i - 1) / (pattern.length - 1);
      double sectionEnd = i / (pattern.length - 1);

      if (progress < sectionStart) break;

      double startX = (i - 1) * dx;
      double startY = size.height - (pattern[i - 1] / 4.0 * size.height);
      double targetX = i * dx;
      double targetY = size.height - (pattern[i] / 4.0 * size.height);

      if (progress >= sectionEnd) {
        path.lineTo(targetX, targetY);
      } else {
        double t = (progress - sectionStart) / (sectionEnd - sectionStart);
        path.lineTo(
          startX + (targetX - startX) * t,
          startY + (targetY - startY) * t,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) {
    return oldDelegate.pattern != pattern ||
        oldDelegate.color != color ||
        oldDelegate.progress != progress;
  }
}
