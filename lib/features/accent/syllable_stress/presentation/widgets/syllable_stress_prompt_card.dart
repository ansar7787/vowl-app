import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

/// Prompt card presenting the full vocabulary word under lexical stress analysis.
class SyllableStressPromptCard extends StatelessWidget {
  /// The target vocabulary word.
  final String word;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [SyllableStressPromptCard] widget.
  const SyllableStressPromptCard({
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
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.06 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                  "WORD",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 2.0,
                      ),
                    ),
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
