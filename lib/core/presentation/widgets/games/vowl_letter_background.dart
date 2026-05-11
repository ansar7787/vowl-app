import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum VowlBackgroundStyle { scatter, focal, grid }

class VowlLetterBackground extends StatelessWidget {
  final Color color;
  final VowlBackgroundStyle style;

  const VowlLetterBackground({
    super.key,
    this.color = Colors.white10,
    this.style = VowlBackgroundStyle.scatter,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _VowlLetterPainter(color: color, style: style),
        ),
      ),
    );
  }
}

class _VowlLetterPainter extends CustomPainter {
  final Color color;
  final VowlBackgroundStyle style;

  _VowlLetterPainter({required this.color, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const letters = ['V', 'O', 'W', 'L'];
    final random = math.Random(42); // Consistent seed for specific map look

    if (style == VowlBackgroundStyle.scatter) {
      for (int i = 0; i < 15; i++) {
        final letter = letters[random.nextInt(letters.length)];
        final fontSize = 40.sp + random.nextDouble() * 100.sp;
        final position = Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        );
        final rotation = random.nextDouble() * math.pi * 2;

        _drawLetter(canvas, letter, position, fontSize, rotation, paint);
      }
    } else if (style == VowlBackgroundStyle.focal) {
      final letter = letters[random.nextInt(letters.length)];
      _drawLetter(
        canvas,
        letter,
        Offset(size.width * 0.5, size.height * 0.3),
        300.sp,
        0.2,
        paint,
      );
      _drawLetter(
        canvas,
        letters[random.nextInt(letters.length)],
        Offset(size.width * 0.2, size.height * 0.8),
        200.sp,
        -0.4,
        paint,
      );
    } else {
      // Grid style
      final spacing = 150.w;
      for (double x = 0; x < size.width; x += spacing) {
        for (double y = 0; y < size.height; y += spacing) {
          final letter = letters[random.nextInt(letters.length)];
          _drawLetter(canvas, letter, Offset(x, y), 50.sp, 0, paint);
        }
      }
    }
  }

  void _drawLetter(
    Canvas canvas,
    String letter,
    Offset position,
    double fontSize,
    double rotation,
    Paint paint,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          fontFamily: 'Outfit', // Using the app's font
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
