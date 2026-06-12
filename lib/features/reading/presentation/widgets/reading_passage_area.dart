import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Displays the reading passage above the question area.
///
/// Scrollable when content exceeds [maxHeight] so the passage never
/// clips on small screens. A [Scrollbar] gives sighted users a visual cue
/// that more content exists below the fold.
///
/// Screen readers access the full passage text via the Semantics label.
class ReadingPassageArea extends StatelessWidget {
  final String passage;
  final Color primaryColor;
  final bool isDark;

  const ReadingPassageArea({
    super.key,
    required this.passage,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget container = Semantics(
      label: 'Reading passage: $passage',
      // The Text inside is redundant to the label above for screen readers.
      excludeSemantics: true,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        padding: EdgeInsets.all(16.r),
        constraints: BoxConstraints(maxHeight: 200.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Text(
              passage,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) return container;
    return container.animate().fadeIn().slideY(begin: -0.1, end: 0);
  }
}
