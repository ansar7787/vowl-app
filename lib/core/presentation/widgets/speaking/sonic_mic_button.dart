import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SonicMicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final Color primaryColor;

  const SonicMicButton({
    super.key,
    required this.isListening,
    required this.onStart,
    required this.onStop,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      padding: EdgeInsets.all(isListening ? 12.r : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: primaryColor.withValues(alpha: isListening ? 0.3 : 0),
          width: 4,
        ),
      ),
      child: GestureDetector(
        onLongPressStart: (_) => onStart(),
        onLongPressEnd: (_) => onStop(),
        onTapDown: (_) => onStart(),
        onTapUp: (_) => onStop(),
        child: ScaleButton(
          onTap: () {}, // Handled by gestures
          child: Container(
            width: 90.r,
            height: 90.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isListening
                    ? [Colors.redAccent, Colors.red]
                    : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening ? Colors.redAccent : primaryColor)
                      .withValues(alpha: 0.4),
                  blurRadius: isListening ? 40 : 20,
                  spreadRadius: isListening ? 10 : 0,
                ),
              ],
            ),
            child:
                Icon(
                      isListening
                          ? Icons.graphic_eq_rounded
                          : Icons.mic_rounded,
                      color: Colors.white,
                      size: 40.r,
                    )
                    .animate(target: isListening ? 1 : 0)
                    .scale(duration: 200.ms)
                    .shimmer(duration: 1000.ms, color: Colors.white24),
          ),
        ),
      ),
    );
  }
}
