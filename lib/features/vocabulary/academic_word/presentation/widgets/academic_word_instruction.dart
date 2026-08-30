import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/academic_word/academic_word_constants.dart';

/// Animated pill-shaped instruction banner at the top of the game.
class AcademicWordInstruction extends StatelessWidget {
  final Color color;
  final String label;

  const AcademicWordInstruction({
    super.key,
    required this.color,
    this.label = AcademicWordStrings.instruction,
  });

  static TextStyle _labelStyle(Color color) => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: color,
    letterSpacing: 2,
  );

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.1,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            constraints: BoxConstraints(maxWidth: 320.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: _labelStyle(color),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms)
        .shimmer(duration: 2.seconds);
  }
}
