import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Action button used to submit and evaluate assembled sentences.
class WordReorderCheckButton extends StatelessWidget {
  /// Whether any words have been placed into the assembly area.
  final bool hasWords;

  /// Whether dark theme styling is active.
  final bool isDark;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Callback invoked when the check button is pressed.
  final VoidCallback onCheck;

  /// Creates a [WordReorderCheckButton] widget.
  const WordReorderCheckButton({
    super.key,
    required this.hasWords,
    required this.isDark,
    required this.primaryColor,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final button = ScaleButton(
      key: const ValueKey('word_check_button'),
      onTap: hasWords ? onCheck : null,
      child: Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: hasWords
                ? [primaryColor, primaryColor.withValues(alpha: 0.85)]
                : [
                    Colors.grey.withValues(alpha: 0.25),
                    Colors.grey.withValues(alpha: 0.35),
                  ],
          ),
          boxShadow: hasWords
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            "Check Sentence",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: hasWords
                  ? Colors.white
                  : (isDark ? Colors.white38 : Colors.black38),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) return button;
    return button.animate().fadeIn(duration: 400.ms);
  }
}
