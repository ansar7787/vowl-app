import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/game_scrollbar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_learn_quest.dart';
import 'topic_word_item_card.dart';

/// Clean semantic word overview for the Learn phase with balanced typography,
/// real-world English usage context, and strongly-typed domain models.
class TopicBlueprintTree extends StatelessWidget {
  final String conceptTitle;
  final String topicEmoji;
  final List<TopicCategory> categories;
  final String? contrastInsight;
  final Color accentColor;

  const TopicBlueprintTree({
    super.key,
    required this.conceptTitle,
    required this.topicEmoji,
    required this.categories,
    this.contrastInsight,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GameScrollbar(
      thumbColor: accentColor.withValues(alpha: 0.55),
      thickness: 3.5.w,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  alignment: Alignment.center,
                  child: topicEmoji.isNotEmpty
                      ? Text(
                          topicEmoji,
                          style: TextStyle(fontSize: 18.sp),
                        )
                      : Icon(
                          Icons.school_rounded,
                          size: 20.r,
                          color: accentColor,
                        ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AutoSizeText(
                    conceptTitle,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Contrast Insight
          if (contrastInsight != null && contrastInsight!.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800
                    : AppColors.amber500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.amber500,
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      contrastInsight!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Category Cards
          ...categories.map((cat) {
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Title
                  Row(
                    children: [
                      Container(
                        width: 26.r,
                        height: 26.r,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        alignment: Alignment.center,
                        child: cat.emoji.isNotEmpty
                            ? Text(
                                cat.emoji,
                                style: TextStyle(fontSize: 14.sp),
                              )
                            : Icon(
                                Icons.category_rounded,
                                size: 15.r,
                                color: accentColor,
                              ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AutoSizeText(
                          cat.name,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (cat.description.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      cat.description,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                  SizedBox(height: 10.h),

                  // Word items with audio and 1-click on-device AI translation
                  ...cat.words.map((w) {
                    return TopicWordItemCard(
                      word: w,
                      accentColor: accentColor,
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}
}
