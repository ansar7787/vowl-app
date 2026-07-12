import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/thermal_grid_painter.dart';

class PronunciationFocusThermalGrid extends StatelessWidget {
  final double heatLevel;
  final bool isListening;
  final double timeVal;
  final bool isDark;

  const PronunciationFocusThermalGrid({
    super.key,
    required this.heatLevel,
    required this.isListening,
    required this.timeVal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 120.h,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0C0C16)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: CustomPaint(
          painter: ThermalGridPainter(
            heatLevel: heatLevel,
            isListening: isListening,
            time: timeVal,
          ),
        ),
      ),
    );
  }
}
