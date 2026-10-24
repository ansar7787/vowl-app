import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

/// Card widget displaying the original story excerpt to be summarized.
class SummarizeStoryManuscript extends StatelessWidget {
  /// The full text of the story excerpt.
  final String story;

  /// Theme accent color applied to borders and heading icons.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Creates a [SummarizeStoryManuscript] widget.
  const SummarizeStoryManuscript({
    super.key,
    required this.story,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.5.r),
        child: Stack(
          children: [
            const Positioned.fill(
              child: TechPatternOverlay(opacity: 0.03),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 16.r,
                        color: color,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'STORY',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    story,
                    textAlign: TextAlign.start,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.92)
                          : AppColors.slate800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
