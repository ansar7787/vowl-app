import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class IntonationMimicRollercoaster extends StatelessWidget {
  final List<int> contour;
  final Color color;
  final bool isDark;
  final bool isRiding;
  final double cartPosition;

  const IntonationMimicRollercoaster({
    super.key,
    required this.contour,
    required this.color,
    required this.isDark,
    required this.isRiding,
    required this.cartPosition,
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
          // Rails
          Center(
            child: CustomPaint(
              size: Size(0.7.sw, 100.h),
              painter: _TrackPainter(contour, color.withValues(alpha: 0.2)),
            ),
          ),
          // Progress Glow
          if (isRiding)
            Center(
              child: CustomPaint(
                size: Size(0.7.sw, 100.h),
                painter: _TrackPainter(contour, color, progress: cartPosition),
              ),
            ),
          // Cart (Glowing Spaceship)
          _buildCart(contour, color),
        ],
      ),
    );
  }

  Widget _buildCart(List<int> contour, Color color) {
    double posX = 0.12.sw + (cartPosition * 0.7.sw) - 20.w;
    double posY = _getYForPosition(cartPosition, contour) * 70.h + 20.h;

    return Positioned(
      left: posX,
      bottom: posY,
      child: Icon(Icons.navigation_rounded, color: color, size: 36.r)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -2, end: 2, duration: 500.ms),
    );
  }

  double _getYForPosition(double pos, List<int> contour) {
    if (contour.isEmpty) return 0.5;
    int idx = (pos * (contour.length - 1)).floor();
    double subPos = (pos * (contour.length - 1)) - idx;
    if (idx >= contour.length - 1) return contour.last / 3.0;
    return (contour[idx] + (contour[idx+1] - contour[idx]) * subPos) / 3.0;
  }
}

class _TrackPainter extends CustomPainter {
  final List<int> contour;
  final Color color;
  final double progress;
  _TrackPainter(this.contour, this.color, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    if (contour.isEmpty) return;

    double dx = size.width / (contour.length - 1);
    path.moveTo(0, size.height - (contour[0] / 3.0 * size.height));

    for (int i = 1; i < contour.length; i++) {
      if (i / (contour.length - 1) > progress) break;
      path.lineTo(i * dx, size.height - (contour[i] / 3.0 * size.height));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
