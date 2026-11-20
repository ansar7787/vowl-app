import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Back face of the 3D Discovery Card in Flashcard Learn Phase.
class FlashcardLearnBackFace extends StatelessWidget {
  final PhasedQuest quest;
  final bool isDark;
  final VoidCallback onFlip;
  final List<String> collocations;
  final String? commonMistake;
  final String contextDomain;

  const FlashcardLearnBackFace({
    super.key,
    required this.quest,
    required this.isDark,
    required this.onFlip,
    required this.collocations,
    this.commonMistake,
    required this.contextDomain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? AppColors.indigo500.withValues(alpha: 0.35)
              : AppColors.indigo500.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Word & Flip back button header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quest.word ?? '',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate950,
                ),
              ),
              ScaleButton(
                onTap: onFlip,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flip_rounded,
                        size: 14.r,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Front',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // Definition
          Text(
            quest.definition ?? '',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),

          SizedBox(height: 16.h),

          // Real-World Sentence
          if (quest.example != null)
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800.withValues(alpha: 0.6)
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 20.r,
                    color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      quest.example!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 14.h),

          // Natural Collocations
          if (collocations.isNotEmpty) ...[
            Text(
              'NATURAL COLLOCATIONS',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: collocations.map((col) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate300,
                    ),
                  ),
                  child: Text(
                    col,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 14.h),
          ],

          // Common Mistake Alert Box
          if (commonMistake != null)
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18.r,
                    color: Colors.amber.shade700,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      commonMistake!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.amber.shade900,
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
