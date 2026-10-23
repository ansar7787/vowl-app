import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

/// Prompt card displaying the target sentence tested across differing tempos.
class SpeedVariancePromptCard extends StatelessWidget {
  /// Target sentence or utterance.
  final String word;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [SpeedVariancePromptCard] widget.
  const SpeedVariancePromptCard({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 420.w),
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.18),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.04)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    "Sentence",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  word,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: null,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
