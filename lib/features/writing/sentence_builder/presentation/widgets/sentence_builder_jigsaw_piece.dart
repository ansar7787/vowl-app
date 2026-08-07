import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SentenceBuilderJigsawPiece extends StatelessWidget {
  final String text;
  final bool isAssembled;
  final VoidCallback? onTap;
  final Color color;
  final bool isDark;
  final bool isDragging;

  const SentenceBuilderJigsawPiece({
    super.key,
    required this.text,
    required this.isAssembled,
    this.onTap,
    required this.color,
    required this.isDark,
    this.isDragging = false,
  });

  String _formatText(String word) {
    if (word == 'I' ||
        word == "I'm" ||
        word == "I'll" ||
        word == "I've" ||
        word == "I'd") {
      return word;
    }
    return word.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _formatText(text);

    final piece = Semantics(
      label: isAssembled
          ? '$text — tap to remove from workbench'
          : '$text — tap or drag to add to workbench',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 0.8.sw),
          child: CustomPaint(
            painter: _PuzzlePiecePainter(
              color: color,
              shadowColor: color.withValues(alpha: 0.35),
              isAssembled: isAssembled,
              isDark: isDark,
              isDragging: isDragging,
            ),
            child: Padding(
              // The left notch padding and right tab padding ensure text doesn't clip
              padding: EdgeInsets.only(
                left: 20.w,
                right: 28.w,
                top: 10.h,
                bottom: 10.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isAssembled) {
      return piece.animate().shimmer(duration: 600.ms);
    }
    return piece;
  }
}

class _PuzzlePiecePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final bool isAssembled;
  final bool isDark;
  final bool isDragging;

  _PuzzlePiecePainter({
    required this.color,
    required this.shadowColor,
    required this.isAssembled,
    required this.isDark,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tabSize = 12.0.w;
    final radius = 10.0.r;

    final path = Path();

    // Start top-left after radius
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius - tabSize, 0);

    // Top-right corner
    path.quadraticBezierTo(
      size.width - tabSize,
      0,
      size.width - tabSize,
      radius,
    );

    // Right tab (outward)
    path.lineTo(size.width - tabSize, size.height / 2 - tabSize + 2);
    path.quadraticBezierTo(
      size.width,
      size.height / 2 - tabSize + 2,
      size.width,
      size.height / 2,
    );
    path.quadraticBezierTo(
      size.width,
      size.height / 2 + tabSize - 2,
      size.width - tabSize,
      size.height / 2 + tabSize - 2,
    );

    // Bottom-right corner
    path.lineTo(size.width - tabSize, size.height - radius);
    path.quadraticBezierTo(
      size.width - tabSize,
      size.height,
      size.width - tabSize - radius,
      size.height,
    );

    // Bottom edge
    path.lineTo(radius, size.height);

    // Bottom-left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    // Left notch (inward)
    path.lineTo(0, size.height / 2 + tabSize - 2);
    path.quadraticBezierTo(
      tabSize,
      size.height / 2 + tabSize - 2,
      tabSize,
      size.height / 2,
    );
    path.quadraticBezierTo(
      tabSize,
      size.height / 2 - tabSize + 2,
      0,
      size.height / 2 - tabSize + 2,
    );

    // Top-left corner
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    path.close();

    // Draw shadow
    if (isDragging || isAssembled) {
      canvas.drawShadow(path, shadowColor, 8, false);
    } else {
      canvas.drawShadow(
        path,
        Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
        4,
        false,
      );
    }

    // Draw background
    final paint = Paint()
      ..color = isAssembled
          ? color.withValues(alpha: 0.25)
          : (isDark ? const Color(0xFF1E293B) : Colors.white)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = isAssembled ? color : (isDark ? Colors.white24 : Colors.black12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PuzzlePiecePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isAssembled != isAssembled ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isDragging != isDragging;
  }
}
