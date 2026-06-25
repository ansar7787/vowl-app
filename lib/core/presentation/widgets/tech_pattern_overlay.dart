import 'package:flutter/material.dart';

/// Decorative grid backdrop optimised to avoid expensive offscreen blending.
///
/// Alpha is applied directly to the paint stroke colour rather than via an
/// [Opacity] widget (which would trigger a saveLayer call).
///
/// Stroke widths and grid spacing use **logical pixels** (not ScreenUtil `.r`
/// suffixes) so the grid remains visually consistent across all device
/// densities including tablets and foldables.
class TechPatternOverlay extends StatelessWidget {
  final double opacity;
  final Color color;

  const TechPatternOverlay({
    super.key,
    this.opacity = 0.05,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TechPatternPainter(color: color.withValues(alpha: opacity)),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _TechPatternPainter extends CustomPainter {
  final Color color;

  // Logical-pixel constants — consistent across all densities.
  static const double _lineSpacing = 4.0;
  static const double _strokeWidth = 1.0;

  const _TechPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth;

    // Vertical lines
    for (double x = 0; x < size.width; x += _lineSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += _lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TechPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
