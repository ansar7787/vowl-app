import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/controllers/word_formation_controller.dart';

class ReactionCore extends StatelessWidget {
  final GameQuest? quest;
  final String root;
  final String? suffix;
  final Color color;
  final bool isDark;
  final WordFormationController controller;

  const ReactionCore({
    super.key,
    required this.quest,
    required this.root,
    required this.suffix,
    required this.color,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    final isCompleted =
        (controller.isAnswered && controller.isCorrect == true) ||
        controller.isFirstStagePassed;
    final displayWord = isCompleted
        ? (quest?.correctAnswer ?? "")
        : root;

    final cleanAffix = suffix?.trim() ?? '';
    final isPrefix = cleanAffix.endsWith('-') ||
        (!cleanAffix.startsWith('-') &&
            cleanAffix.isNotEmpty &&
            (quest?.correctAnswer ?? '')
                .toLowerCase()
                .startsWith(cleanAffix.replaceAll('-', '').toLowerCase()));

    final cardContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isCompleted
              ? AppColors.gameCorrect.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? AppColors.gameCorrect : color).withValues(
              alpha: 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Category / Status Header
          if (isCompleted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.gameCorrect,
                  size: 14.r,
                ),
                SizedBox(width: 5.w),
                Text(
                  'COMPLETED WORD',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gameCorrect,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            )
          else
            Text(
              'BASE WORD',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          SizedBox(height: 6.h),

          // Main Formation Area
          if (isCompleted)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayWord.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.slate900,
                  letterSpacing: 2.0,
                ),
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 4.h,
              children: [
                // If it's a prefix (e.g. UN-), show it on the LEFT of the root word
                if (suffix != null &&
                    !controller.isAnswered &&
                    !controller.isFirstStagePassed &&
                    isPrefix) ...[
                  _buildAffixChip(suffix!, color),
                  Icon(
                    Icons.add_rounded,
                    color: color,
                    size: 20.r,
                  ),
                ],

                // Base Root Word
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    root.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                // If it's a suffix (e.g. -NESS), show it on the RIGHT of the root word
                if (suffix != null &&
                    !controller.isAnswered &&
                    !controller.isFirstStagePassed &&
                    !isPrefix) ...[
                  Icon(
                    Icons.add_rounded,
                    color: color,
                    size: 20.r,
                  ),
                  _buildAffixChip(suffix!, color),
                ],
              ],
            ),
        ],
      ),
    );

    if (reduceMotion) {
      return cardContent;
    }

    return cardContent
        .animate()
        .fadeIn(duration: 400.ms);
  }

  Widget _buildAffixChip(String affix, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          affix.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
