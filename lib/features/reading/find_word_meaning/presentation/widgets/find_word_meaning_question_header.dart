import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// Header tile presenting the contextual definition for which the word must be found.
class FindWordMeaningQuestionHeader extends StatelessWidget {
  /// The dictionary or contextual definition prompt text.
  final String text;

  /// Theme accent color applied to labels and badges.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Creates a [FindWordMeaningQuestionHeader] widget.
  const FindWordMeaningQuestionHeader({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      borderRadius: BorderRadius.circular(20.r),
      color: null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: color,
              size: 20.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DEFINITION",
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  text,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppColors.slate800,
                    height: 1.42,
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
