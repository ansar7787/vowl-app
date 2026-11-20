import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Modal bottom sheet prompting struggling learners to return to Learn Mode.
///
/// Triggers after repeated consecutive incorrect attempts in Practice Mode,
/// preventing learner frustration and reinforcing pedagogical mastery.
class FlashcardLearnRefresherSheet extends StatelessWidget {
  final int level;
  final VoidCallback onKeepPracticing;

  const FlashcardLearnRefresherSheet({
    super.key,
    required this.level,
    required this.onKeepPracticing,
  });

  /// Shows the refresher prompt as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int level,
    required VoidCallback onKeepPracticing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FlashcardLearnRefresherSheet(
        level: level,
        onKeepPracticing: onKeepPracticing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 24.r,
            offset: Offset(0, -6.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate700 : AppColors.slate300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(
                    alpha: isDark ? 0.25 : 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 32.r,
                  color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Review in Learn Mode?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You have attempted this word multiple times. Would you like to review the syllables, pronunciation, and usage distinctions before continuing?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                height: 1.4,
                color: isDark ? AppColors.slate300 : AppColors.slate600,
              ),
            ),
            SizedBox(height: 24.h),
            ScaleButton(
              onTap: () {
                Navigator.of(context).pop();
                context.pushReplacement(
                  '/learn?category=vocabulary&gameType=flashcards&level=$level',
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Review in Learn Mode',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14.r,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            ScaleButton(
              onTap: () {
                Navigator.of(context).pop();
                onKeepPracticing();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Center(
                  child: Text(
                    'Keep Practicing',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
