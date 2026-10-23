import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom painter rendering connection lines and node sockets for preposition selection.
class PrepositionPathPainter extends CustomPainter {
  /// The collection of trace points representing the user gesture path.
  final List<Offset> points;

  /// The preposition option labels displayed on each node.
  final List<String> options;

  /// The primary accent color for active paths and sockets.
  final Color primaryColor;

  /// Whether the user has submitted an answer for the current turn.
  final bool isAnswered;

  /// Whether the selected answer is correct.
  final bool isCorrect;

  /// The index of the selected target node.
  final int targetNode;

  /// Whether dark theme styling is active.
  final bool isDark;

  /// Whether compact layout spacing should be used.
  final bool isCompact;

  /// Creates a [PrepositionPathPainter] instance.
  PrepositionPathPainter({
    required this.points,
    required this.options,
    required this.primaryColor,
    required this.isAnswered,
    required this.isCorrect,
    required this.targetNode,
    required this.isDark,
    required this.isCompact,
  });

  /// Calculates the starting socket point for the path given [size] and [isCompact].
  static Offset getStartPoint(Size size, bool isCompact) {
    return Offset(size.width / 2, isCompact ? 20.h : 40.h);
  }

  /// Calculates the positions for candidate option nodes given [size], [count], and [isCompact].
  static List<Offset> getNodePoints(Size size, int count, bool isCompact) {
    final List<Offset> nodes = [];
    final double bottomY = size.height - (isCompact ? 40.h : 100.h);

    if (count <= 3) {
      nodes.addAll(
        [
          Offset(isCompact ? 50.w : 80.w, bottomY),
          Offset(size.width / 2, bottomY),
          Offset(size.width - (isCompact ? 50.w : 80.w), bottomY),
        ].take(count),
      );
    } else {
      nodes.addAll([
        Offset(isCompact ? 60.w : 90.w, bottomY - (isCompact ? 50.h : 100.h)),
        Offset(
          size.width - (isCompact ? 60.w : 90.w),
          bottomY - (isCompact ? 50.h : 100.h),
        ),
        Offset(isCompact ? 60.w : 90.w, bottomY),
        Offset(size.width - (isCompact ? 60.w : 90.w), bottomY),
      ]);
    }
    return nodes;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final startPoint = getStartPoint(size, isCompact);
    final nodes = getNodePoints(size, options.length, isCompact);

    // Draw Preposition Choice Nodes
    for (int i = 0; i < nodes.length; i++) {
      final isTarget = isAnswered && targetNode == i;
      final nodeColor = isTarget ? AppColors.gameCorrect : primaryColor;

      // Node Outer Glow
      canvas.drawCircle(
        nodes[i],
        44.r,
        Paint()
          ..color = nodeColor.withValues(alpha: isTarget ? 0.2 : 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Node Background Fill for contrast & readability
      canvas.drawCircle(
        nodes[i],
        38.r,
        Paint()
          ..color = isDark
              ? (isTarget
                    ? AppColors.gameCorrect.withValues(alpha: 0.25)
                    : const Color(0xFF1E2230))
              : (isTarget
                    ? AppColors.gameCorrect.withValues(alpha: 0.15)
                    : Colors.white),
      );

      // Node Ring Border
      canvas.drawCircle(
        nodes[i],
        38.r,
        Paint()
          ..color = nodeColor.withValues(alpha: isTarget ? 0.9 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isTarget ? 2.5 : 1.5,
      );

      final optionText = options[i % options.length];
      final double fontSize = optionText.length > 5
          ? (isCompact ? 11.5.sp : 12.5.sp)
          : (isCompact ? 13.sp : 14.5.sp);

      final textPainter = TextPainter(
        text: TextSpan(
          text: optionText,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: isTarget
                ? AppColors.gameCorrect
                : (isDark ? Colors.white : Colors.black87),
            letterSpacing: 0.3,
            height: 1.1,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 72.r);
      textPainter.paint(
        canvas,
        nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw Anchor Socket
    canvas.drawCircle(
      startPoint,
      16.r,
      Paint()
        ..color = primaryColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(startPoint, 7.r, Paint()..color = Colors.white);

    // Draw Connection Path
    if (points.isNotEmpty || isAnswered) {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      if (isAnswered && targetNode != -1) {
        path.lineTo(nodes[targetNode].dx, nodes[targetNode].dy);
      } else {
        for (var p in points) {
          path.lineTo(p.dx, p.dy);
        }
      }

      final pathColor = isAnswered
          ? (isCorrect ? AppColors.gameCorrect : AppColors.gameIncorrect)
          : primaryColor;

      // Outer Glow
      canvas.drawPath(
        path,
        Paint()
          ..color = pathColor.withValues(alpha: 0.35)
          ..strokeWidth = 9.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Inner Line
      canvas.drawPath(
        path,
        Paint()
          ..color = pathColor
          ..strokeWidth = 3.5.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Core Highlight
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PrepositionPathPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.isAnswered != isAnswered ||
      oldDelegate.targetNode != targetNode;
}
