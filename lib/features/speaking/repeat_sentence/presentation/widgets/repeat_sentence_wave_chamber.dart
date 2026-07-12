import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/visual_trace_painter.dart';

class RepeatSentenceWaveChamber extends StatelessWidget {
  final double progress;
  final bool isListening;
  final Color themeColor;
  final List<double> amplitudes;
  final bool isDark;

  const RepeatSentenceWaveChamber({
    super.key,
    required this.progress,
    required this.isListening,
    required this.themeColor,
    required this.amplitudes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 140.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF07070F)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: CustomPaint(
        painter: VisualTracePainter(
          progress: progress,
          isListening: isListening,
          themeColor: themeColor,
          amplitudes: amplitudes,
        ),
      ),
    );
  }
}
