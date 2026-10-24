import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

/// Prompt card showcasing the sentence to practice alongside emotional pragmatics.
class IntonationMimicPromptCard extends StatelessWidget {
  /// Target phrase or question.
  final String word;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Emotional context cue (e.g. "Polite inquiry", "Surprise").
  final String? emotionContext;

  /// Creates an [IntonationMimicPromptCard] widget.
  const IntonationMimicPromptCard({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
    this.emotionContext,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmotion = emotionContext != null && emotionContext!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.06 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.04)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Sentence to practice",
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 6.h),
                if (hasEmotion) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.25 : 0.18),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      emotionContext!.trim(),
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: null,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
                Text(
                  word,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: null,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.2,
                    height: 1.3,
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
