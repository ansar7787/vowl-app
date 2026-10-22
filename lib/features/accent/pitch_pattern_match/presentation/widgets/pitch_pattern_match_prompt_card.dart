import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

class PitchPatternMatchPromptCard extends StatelessWidget {
  final String word;
  final String? emotionContext;
  final Color color;
  final bool isDark;

  const PitchPatternMatchPromptCard({
    super.key,
    required this.word,
    this.emotionContext,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 420.w),
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "SENTENCE",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            word,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.35,
            ),
          ),
          if (emotionContext != null && emotionContext!.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 5.h,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Text(
                emotionContext!.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
