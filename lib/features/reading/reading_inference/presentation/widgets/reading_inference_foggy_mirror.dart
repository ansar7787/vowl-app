import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class ReadingInferenceFoggyMirror extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final List<Offset> rubPoints;
  final double clarity;
  final Function(Offset) onRub;

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
      child: Stack(
        children: [
          // Clear Passage Text
          GlassTile(
            padding: EdgeInsets.all(26.r),
            borderRadius: BorderRadius.circular(24.r),
            color: color.withValues(alpha: isDark ? 0.05 : 0.08),
            child: Text(
              passage, 
              textAlign: TextAlign.center, 
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 16.sp, 
                height: 1.4,
                color: isDark ? Colors.white : Colors.black87, 
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Fog Cover Layer
          if (!isAnswered)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: CustomPaint(
                  painter: FogPainter(
                    points: rubPoints, 
                    clarity: clarity, 
                    color: isDark ? Colors.grey.shade800 : Colors.blueGrey.shade100,
                  ),
                ),
              ),
            ),
          
          // Glowing clues overlay
          if (clarity > 0.5 && !isAnswered)
            Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.lightbulb_outline_rounded, 
                  color: Colors.amber.withValues(alpha: 0.35), 
                  size: 80.r,
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
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
      ..color = color.withValues(alpha: 0.95 - (clarity * 0.4))
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 35.r
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], clearPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
