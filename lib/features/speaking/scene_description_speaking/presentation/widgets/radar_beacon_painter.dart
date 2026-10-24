import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom painter rendering a pulsating scenic radar beacon pinging exploration nodes.
class RadarBeaconPainter extends CustomPainter {
  /// Pulse expansion animation progress fraction (0.0 to 1.0).
  final double progress;

  /// Whether the radar beacon is currently pinging and scanning.
  final bool isActive;

  /// Whether the target scene node has been successfully identified.
  final bool isCompleted;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Creates a [RadarBeaconPainter].
  RadarBeaconPainter({
    required this.progress,
    required this.isActive,
    required this.isCompleted,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    if (isCompleted) {
      // Completed solid static emerald green glow
      final Paint solidPaint = Paint()
        ..color = AppColors.gameCorrect
        ..style = PaintingStyle.fill;
      final Paint glowPaint = Paint()
        ..color = AppColors.gameCorrect.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.r);

      canvas.drawCircle(center, maxRadius * 0.4, glowPaint);
      canvas.drawCircle(center, maxRadius * 0.35, solidPaint);
      return;
    }

    if (isActive) {
      // Rapid active glowing expansion ripples
      final rippleAlpha = (1.0 - progress).clamp(0.0, 1.0);
      final rippleRadius = (maxRadius * progress).clamp(0.0, maxRadius);
      final Paint ripplePaint = Paint()
        ..color = primaryColor.withValues(alpha: rippleAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.w;

      final Paint corePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, rippleRadius, ripplePaint);
      canvas.drawCircle(center, maxRadius * 0.4, corePaint);
    } else {
      // Gentle floating sleeping beacons
      final sleepAlpha =
          (0.2 + (0.3 * math.sin(progress * math.pi * 2))).clamp(0.0, 1.0);
      final Paint sleepPaint = Paint()
        ..color = primaryColor.withValues(alpha: sleepAlpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius * 0.45, sleepPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarBeaconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isCompleted != isCompleted;
  }
}
