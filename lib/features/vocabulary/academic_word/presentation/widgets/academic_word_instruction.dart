import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Animated pill-shaped instruction banner at the top of the game.
class AcademicWordInstruction extends StatelessWidget {
  final Color color;
  final String label;

  const AcademicWordInstruction({
    super.key,
    required this.color,
    required this.label,
  });

  static TextStyle _labelStyle(Color color) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 13.5.sp,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.35,
    letterSpacing: 0.2,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final banner = Semantics(
      container: true,
      label: label,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.5,
        child: Container(
          key: const Key('academic_word_instruction'),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          constraints: BoxConstraints(maxWidth: 340.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: VowlMotion.lowAnimationModeOverride.value
              ? Text(
                  label,
                  key: const Key('academic_word_instruction_text'),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: _labelStyle(color),
                )
              : Text(
                  label,
                  key: const Key('academic_word_instruction_text'),
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: _labelStyle(color),
                ).animate().shimmer(duration: 2.seconds),
        ),
      ),
    );

    if (VowlMotion.lowAnimationModeOverride.value) {
      return banner;
    }
    return banner.animate().fadeIn(duration: 600.ms);
  }
}
