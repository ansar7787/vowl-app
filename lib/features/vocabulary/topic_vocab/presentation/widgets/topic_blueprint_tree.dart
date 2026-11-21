import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_learn_quest.dart';

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

    return SingleChildScrollView(
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
                Text(topicEmoji, style: TextStyle(fontSize: 24.sp)),
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
                color: AppColors.amber500.withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Title
                  Row(
                    children: [
                      Text(cat.emoji, style: TextStyle(fontSize: 18.sp)),
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

                  // Word items
                  ...cat.words.map((w) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      w.word,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (w.ipa.isNotEmpty) ...[
                                      SizedBox(width: 6.w),
                                      Text(
                                        w.ipa,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w400,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              TtsSpeakerButtonWidget(
                                text: w.word,
                                color: accentColor,
                                size: 26.r,
                              ),
                            ],
                          ),
                          if (w.definition.isNotEmpty) ...[
                            SizedBox(height: 3.h),
                            Text(
                              w.definition,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                          if (w.collocation.isNotEmpty) ...[
                            SizedBox(height: 5.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 11.r,
                                    color: accentColor,
                                  ),
                                  SizedBox(width: 4.w),
                                  Flexible(
                                    child: Text(
                                      w.collocation,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
