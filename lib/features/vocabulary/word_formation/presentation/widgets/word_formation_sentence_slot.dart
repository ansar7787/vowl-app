import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'word_formation_colors.dart';
import 'word_formation_morpheme_formula.dart';

/// Card rendering the sentence context with an animated morphological slot.
class WordFormationSentenceSlot extends StatelessWidget {
  final String sentence;
  final String? formedWord;
  final String? rootWord;
  final String? targetRole;
  final String? roleClue;
  final bool isAnswered;
  final bool? isCorrect;
  final Color primaryColor;
  final String? bounceFeedback;
  final int shakeCount;

  const WordFormationSentenceSlot({
    super.key,
    required this.sentence,
    this.formedWord,
    this.rootWord,
    this.targetRole,
    this.roleClue,
    required this.isAnswered,
    this.isCorrect,
    required this.primaryColor,
    this.bounceFeedback,
    this.shakeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = sentence.split('_______');
    final beforeText = parts.isNotEmpty ? parts[0] : sentence;
    final afterText = parts.length > 1 ? parts[1] : '';
    final roleColor = WordFormationColors.forRole(targetRole);

    final cardContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCorrect == true
              ? AppColors.gameCorrect.withValues(alpha: 0.45)
              : (isCorrect == false
                    ? AppColors.gameIncorrect.withValues(alpha: 0.45)
                    : roleColor.withValues(alpha: 0.28)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isAnswered && isCorrect == true
                ? AppColors.gameCorrect.withValues(alpha: 0.1)
                : roleColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Root Word Pill (if provided) & Role Clue Badge
          Row(
            children: [
              if (rootWord != null && rootWord!.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.28),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ROOT: ${rootWord!.toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      ScaleButton(
                        onTap: () => di.sl<TtsService>().speak(rootWord!),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: primaryColor,
                          size: 13.r,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: roleColor.withValues(alpha: 0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_fix_normal_rounded,
                        color: roleColor,
                        size: 14.r,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          targetRole != null
                              ? 'TARGET: ${targetRole!.toUpperCase()}'
                              : 'FILL IN THE BLANK',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isAnswered && formedWord != null) ...[
                const Spacer(),
                ScaleButton(
                  onTap: () {
                    final fullText = sentence.replaceAll(
                      '_______',
                      formedWord!,
                    );
                    di.sl<TtsService>().speak(fullText);
                  },
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: primaryColor,
                      size: 18.r,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),

          // Main Sentence Flow with Embedded Slot
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.5,
              ),
              children: [
                TextSpan(text: beforeText),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 3.h,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? (isCorrect == true
                                ? AppColors.gameCorrect.withValues(alpha: 0.16)
                                : AppColors.gameIncorrect.withValues(
                                    alpha: 0.16,
                                  ))
                          : roleColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isAnswered
                            ? (isCorrect == true
                                  ? AppColors.gameCorrect
                                  : AppColors.gameIncorrect)
                            : roleColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      isAnswered && formedWord != null
                          ? formedWord!.toUpperCase()
                          : (targetRole != null ? '[$targetRole]' : '_______'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: isAnswered
                            ? (isCorrect == true
                                  ? AppColors.gameCorrect
                                  : AppColors.gameIncorrect)
                            : roleColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: afterText),
              ],
            ),
          ),

          // Role Clue or Bounce Feedback
          if (roleClue != null && !isAnswered) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: primaryColor.withValues(alpha: 0.8),
                  size: 14.r,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    roleClue!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (isAnswered &&
              isCorrect == true &&
              formedWord != null &&
              rootWord != null) ...[
            SizedBox(height: 12.h),
            WordFormationMorphemeFormula(
              rootWord: rootWord!,
              formedWord: formedWord!,
              targetRole: targetRole,
            ),
          ],

          if (isCorrect == false && bounceFeedback != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.gameIncorrect.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.gameIncorrect.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.replay_rounded,
                    color: AppColors.gameIncorrect,
                    size: 16.r,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      bounceFeedback!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gameIncorrect,
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

    return ShakeableWrapper(
      shakeCount: shakeCount,
      child: cardContent,
    );
  }
}
