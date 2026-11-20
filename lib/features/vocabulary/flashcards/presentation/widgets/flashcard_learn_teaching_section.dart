import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Educational discovery section for the Flashcard Learn Phase.
///
/// Displays visual anchors, native speaker tips, pitfalls, word families,
/// and pedagogical teaching cards.
class FlashcardLearnTeachingSection extends StatelessWidget {
  final PhasedQuest quest;
  final bool isDark;
  final void Function(String text) onSpeak;

  const FlashcardLearnTeachingSection({
    super.key,
    required this.quest,
    required this.isDark,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Visual Anchor
        if (quest.visualAnchor != null && quest.visualAnchor!.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.slate900.withValues(alpha: 0.6)
                  : AppColors.slate100,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
            ),
            child: Row(
              children: [
                Text('🧠', style: TextStyle(fontSize: 18.sp)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    quest.visualAnchor!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // 2. Native Speaker Tip
        if (quest.nativeTip != null && quest.nativeTip!.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡', style: TextStyle(fontSize: 20.sp)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NATIVE SPEAKER TIP',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.amber.shade300
                              : Colors.amber.shade800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        quest.nativeTip!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // 3. Usage Nuance
        if (quest.usageExample != null && quest.usageExample!.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.indigo500.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.indigo400,
                  size: 18.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USAGE NUANCE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo400,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        quest.usageExample!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.5.sp,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // 4. Common Mistake Alert
        if (quest.commonMistake != null && quest.commonMistake!.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️', style: TextStyle(fontSize: 16.sp)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PITFALL TO AVOID',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade400,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        quest.commonMistake!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // 5. Word Family Pills
        if (quest.familyWords.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORD FAMILY & VARIATIONS',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.indigo500,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: quest.familyWords.map((word) {
                    return ScaleButton(
                      onTap: () => onSpeak(word),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate800
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.indigo500.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.volume_up_rounded,
                              size: 14.r,
                              color: AppColors.indigo400,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // 6. Deep Insight / Teaching Cards
        if (quest.teachingCards.isNotEmpty) ...[
          for (final card in quest.teachingCards) ...[
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: AppColors.indigo500,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          card.title.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    card.explanation,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      color: isDark ? AppColors.slate300 : AppColors.slate800,
                      height: 1.4,
                    ),
                  ),
                  if (card.nativeSpeakerInsight != null &&
                      card.nativeSpeakerInsight!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Insight: ${card.nativeSpeakerInsight!}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.indigo400
                              : AppColors.indigo600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14.h),
          ],
        ],
      ],
    );
  }
}
