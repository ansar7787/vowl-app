import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

class HarmonicWaves extends StatelessWidget {
  final Color color;
  final double? height;
  final double? width;
  const HarmonicWaves({
    super.key,
    required this.color,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = height ?? 200.h;
        final w =
            width ??
            (constraints.hasBoundedWidth ? constraints.maxWidth : 1.sw);

        return SizedBox(
          height: h,
          width: w,
          child: ClipRect(
            child: Stack(
              children: List.generate(3, (index) {
                return Positioned(
                  bottom: -(h * 0.25) + (index * (h * 0.1)),
                  left: -w * 0.2,
                  right: -w * 0.2,
                  child:
                      Opacity(
                            opacity: 0.1 - (index * 0.02),
                            child: CustomPaint(
                              size: Size(w, h),
                              painter: WavePainter(
                                color: color,
                                phase: index * math.pi / 4,
                                frequency: 1 + (index * 0.5),
                                waveHeight: h * 0.25,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .moveX(
                            begin: -w * 0.1,
                            end: w * 0.1,
                            duration: (3000 + index * 1000).ms,
                            curve: Curves.easeInOutSine,
                          ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double phase;
  final double frequency;
  final double waveHeight;

  WavePainter({
    required this.color,
    required this.phase,
    required this.frequency,
    required this.waveHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height / 2 +
            math.sin((i / size.width * 2 * math.pi * frequency) + phase) *
                waveHeight,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
