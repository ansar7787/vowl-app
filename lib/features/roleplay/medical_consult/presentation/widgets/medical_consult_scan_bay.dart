import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_radar_painter.dart';

class MedicalConsultScanBay extends StatelessWidget {
  final List<String> symptoms;
  final Color color;
  final bool isDark;
  final Offset scanOffset;
  final List<String> scannedGlitches;
  final Animation<double> sweepAnimation;
  final Function(DragUpdateDetails, List<String>) onScanUpdate;

  const MedicalConsultScanBay({
    super.key,
    required this.symptoms,
    required this.color,
    required this.isDark,
    required this.scanOffset,
    required this.scannedGlitches,
    required this.sweepAnimation,
    required this.onScanUpdate,
  });

  Offset _getAnatomicalOffset(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("head") || lower.contains("brain") || lower.contains("sensor") || lower.contains("sensory")) {
      return Offset(0, -95.h);
    }
    if (lower.contains("left limb") || lower.contains("left arm") || lower.contains("left hand")) {
      return Offset(-64.w, -5.h);
    }
    if (lower.contains("right wing") || lower.contains("right limb") || lower.contains("right arm") || lower.contains("right hand")) {
      return Offset(64.w, -5.h);
    }
    if (lower.contains("core") || lower.contains("central") || lower.contains("chest") || lower.contains("heart")) {
      return Offset(0, -25.h);
    }
    if (lower.contains("left leg") || lower.contains("left foot")) {
      return Offset(-32.w, 90.h);
    }
    return Offset(32.w, 90.h); // Default Right Leg coordinate
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 330.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Cybernetic scan matrix background grids
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36.r),
              child: AnimatedBuilder(
                animation: sweepAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BiometricRadarPainter(
                      animationValue: sweepAnimation.value,
                      themeColor: color,
                    ),
                  );
                },
              ),
            ),
          ),

          // Glowing wireframe patient body
          Center(
            child: Icon(
              Icons.accessibility_new_rounded,
              size: 260.r,
              color: color.withValues(alpha: 0.1),
            ).animate(
              onPlay: (c) => c.repeat(reverse: true),
            ).shimmer(
              duration: 2.2.seconds,
              color: color.withValues(alpha: 0.35),
            ),
          ),

          // Render active symptom glitch circles dynamically mapped anatomically
          ...symptoms.map((s) {
            final Offset pos = _getAnatomicalOffset(s);
            final bool isResolved = scannedGlitches.contains(s);

            return Positioned(
              left: (1.sw / 2) - 16.w + pos.dx,
              top: (330.h / 2) - 16.h + pos.dy,
              child: Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isResolved
                      ? color.withValues(alpha: 0.2)
                      : Colors.redAccent.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isResolved ? color : Colors.redAccent.withValues(alpha: 0.7),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isResolved ? color : Colors.redAccent).withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isResolved ? Icons.check_circle_outline_rounded : Icons.warning_rounded,
                    color: isResolved ? color : Colors.redAccent,
                    size: 14.r,
                  ),
                ),
              ).animate(
                onPlay: (c) => c.repeat(reverse: true),
              ).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
            );
          }),

          // Interactive Drag-to-Scan lens
          Positioned(
            left: (1.sw / 2) - 50.w + scanOffset.dx,
            top: (330.h / 2) - 50.h + scanOffset.dy,
            child: GestureDetector(
              onPanUpdate: (d) => onScanUpdate(d, symptoms),
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3.0),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 15,
                    ),
                  ],
                  color: color.withValues(alpha: 0.05),
                ),
                child: Center(
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    color: color,
                    size: 36.r,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
