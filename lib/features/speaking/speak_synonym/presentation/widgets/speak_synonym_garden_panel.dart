import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/bloom_painter.dart';

class SpeakSynonymGardenPanel extends StatelessWidget {
  final double bloomProgress;
  final Color primaryColor;
  final bool isListening;
  final double timeVal;
  final bool isDark;

  const SpeakSynonymGardenPanel({
    super.key,
    required this.bloomProgress,
    required this.primaryColor,
    required this.isListening,
    required this.timeVal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 180.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C16) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Stack(
          children: [
            // Glowing background aura
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: isListening ? 0.35 : 0.05,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [primaryColor, Colors.transparent],
                      radius: 0.7,
                    ),
                  ),
                ),
              ),
            ),
            
            // Central blooming CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: BloomPainter(
                  progress: bloomProgress,
                  primaryColor: primaryColor,
                  isListening: isListening,
                  time: timeVal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
