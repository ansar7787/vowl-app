import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/thermal_grid_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color0c0c16 = Color(0xFF0C0C16);
}

/// Visualization container rendering acoustic thermal frequency lines for pronunciation.
class PronunciationFocusThermalGrid extends StatelessWidget {
  /// Heat level indicating acoustic match intensity.
  final double heatLevel;

  /// Whether active microphone input is listening.
  final bool isListening;

  /// Timeline animation value.
  final double timeVal;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [PronunciationFocusThermalGrid].
  const PronunciationFocusThermalGrid({
    super.key,
    required this.heatLevel,
    required this.isListening,
    required this.timeVal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Accent heat visualization grid",
      child: Container(
        width: double.infinity,
        height: 110.h,
        decoration: BoxDecoration(
          color: isDark
              ? _LocalPalette.color0c0c16
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.06),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: CustomPaint(
            painter: ThermalGridPainter(
              heatLevel: heatLevel,
              isListening: isListening,
              time: timeVal,
            ),
          ),
        ),
      ),
    );
  }
}
