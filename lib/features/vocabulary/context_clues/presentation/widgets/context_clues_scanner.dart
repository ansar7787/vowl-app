import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_painters.dart';

class ContextCluesScanner extends StatelessWidget {
  final Color color;

  const ContextCluesScanner({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Ring
        Container(
          width: 160.r,
          height: 160.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Glass Inner with UV Effect
        Container(
          width: 144.r,
          height: 144.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Scanner Crosshair
        CustomPaint(
          size: Size(120.r, 120.r),
          painter: ScannerCrosshairPainter(color),
        ),
        // Handle
        Transform.translate(
          offset: const Offset(60, 60),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 15.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
