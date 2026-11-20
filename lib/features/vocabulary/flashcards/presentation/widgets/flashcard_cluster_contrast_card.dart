import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Side-by-side nuance comparison card contrasting the 3 words in a level cluster.
///
/// Directly eliminates competitor weakness where words are learned in isolation
/// without clarifying usage boundaries and native collocation contrasts.
class FlashcardClusterContrastCard extends StatelessWidget {
  final List<PhasedQuest> quests;
  final bool isDark;
  final VoidCallback onProceed;
  final VoidCallback? onBackToCards;

  const FlashcardClusterContrastCard({
    super.key,
    required this.quests,
    required this.isDark,
    required this.onProceed,
    this.onBackToCards,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200 && onBackToCards != null) {
          onBackToCards!();
        }
      },
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark ? AppColors.slate800 : AppColors.slate200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.indigo500.withValues(alpha: 0.2)
                        : AppColors.indigo500.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 20.r,
                    color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOW TO CHOOSE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.indigo400
                              : AppColors.indigo600,
                        ),
                      ),
                      Text(
                        'Word Usage Distinction',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onBackToCards != null)
                  ScaleButton(
                    onTap: onBackToCards!,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate800 : AppColors.slate100,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Cards',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16.h),

            // The 3 Word Breakdown Cards
            ...List.generate(quests.length, (idx) {
              final q = quests[idx];
              final word = q.word ?? '';
              final domain =
                  q.rawExtra['contextDomain'] as String? ?? 'General Context';
              final rawCollocations =
                  q.rawExtra['collocations'] as List<dynamic>?;
              final primaryCollocation =
                  rawCollocations != null && rawCollocations.isNotEmpty
                  ? rawCollocations.first.toString()
                  : (q.familyWords.isNotEmpty ? q.familyWords.first : '');
              final mistake =
                  q.commonMistake ??
                  q.rawExtra['commonConfusionAlert'] as String?;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.slate800.withValues(alpha: 0.5)
                      : AppColors.slate50,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate700 : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          word,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate950,
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.indigo500.withValues(alpha: 0.25)
                                  : AppColors.indigo500.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                domain,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.indigo400
                                      : AppColors.indigo600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    if (primaryCollocation.isNotEmpty) ...[
                      RichText(
                        text: TextSpan(
                          text: 'Natural match: ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                          ),
                          children: [
                            TextSpan(
                              text: primaryCollocation,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.amberAccent
                                    : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                    if (mistake != null)
                      Text(
                        mistake,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                  ],
                ),
              );
            }),

            SizedBox(height: 8.h),

            // Start Practice Button
            ScaleButton(
              onTap: onProceed,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.35),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Guided Practice',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
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
          ],
        ),
      ),
    );
  }
}
