import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/plasma_painter.dart';

class SpeakOppositePlasmaConduitPanel extends StatelessWidget {
  final double pullProgress;
  final Color primaryColor;
  final bool isListening;
  final double timeVal;
  final bool isDark;

  const SpeakOppositePlasmaConduitPanel({
    super.key,
    required this.pullProgress,
    required this.primaryColor,
    required this.isListening,
    required this.timeVal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 160.h,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0C0C16)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Stack(
          children: [
            // Dynamic energy wave background
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: isListening ? 0.3 : 0.05,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.redAccent, Colors.cyanAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // Plasma CustomPaint
            Positioned.fill(
              child: CustomPaint(
                painter: PlasmaPainter(
                  progress: pullProgress,
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
