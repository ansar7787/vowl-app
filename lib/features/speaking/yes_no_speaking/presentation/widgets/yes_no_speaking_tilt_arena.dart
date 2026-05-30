import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/track_painter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class YesNoSpeakingTiltArena extends StatelessWidget {
  final double tiltValue;
  final bool isSnapped;
  final Color primaryColor;
  final bool isDark;
  final Function(DragUpdateDetails, double) onTiltDragged;
  final VoidCallback onTiltDragEnd;

  const YesNoSpeakingTiltArena({
    super.key,
    required this.tiltValue,
    required this.isSnapped,
    required this.primaryColor,
    required this.isDark,
    required this.onTiltDragged,
    required this.onTiltDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final double trackWidth = 280.w;

    return Container(
      width: 1.sw,
      height: 150.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Neon track custom painter
          Positioned.fill(
            child: CustomPaint(
              painter: TrackPainter(
                tiltValue: tiltValue,
                themeColor: primaryColor,
              ),
            ),
          ),

          // 2. Boundary gate zones
          Positioned(
            left: 12.w,
            child: _buildGateZone("NO (MISMATCH)", Colors.redAccent, tiltValue <= -0.85),
          ),
          Positioned(
            right: 12.w,
            child: _buildGateZone("YES (MATCH)", Colors.greenAccent, tiltValue >= 0.85),
          ),

          // 3. Central dragging glowing sphere
          Positioned(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => onTiltDragged(details, trackWidth),
              onHorizontalDragEnd: (_) => onTiltDragEnd(),
              child: Transform.translate(
                offset: Offset(tiltValue * (trackWidth / 2 - 40.w), 0),
                child: ScaleButton(
                  onTap: () {},
                  child: Container(
                    width: 66.r,
                    height: 66.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          tiltValue < 0
                              ? Colors.redAccent
                              : (tiltValue > 0 ? Colors.greenAccent : primaryColor),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (tiltValue < 0
                                  ? Colors.redAccent
                                  : (tiltValue > 0 ? Colors.greenAccent : primaryColor))
                              .withValues(alpha: 0.45),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Icon(
                      isSnapped ? Icons.lock_rounded : Icons.blur_on_rounded,
                      color: Colors.white,
                      size: 26.r,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateZone(String label, Color color, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? Colors.white24 : color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                )
              ]
            : [],
      ),
      child: Text(
        label,
        style: GoogleFonts.shareTechMono(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.white : color,
        ),
      ),
    );
  }
}
