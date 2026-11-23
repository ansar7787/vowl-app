import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Card rendering the sentence context with an animated morphological slot.
class WordFormationSentenceSlot extends StatelessWidget {
  final String sentence;
  final String? formedWord;
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

    final cardContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isAnswered
              ? (isCorrect == true
                    ? AppColors.gameCorrect.withValues(alpha: 0.5)
                    : AppColors.gameIncorrect.withValues(alpha: 0.5))
              : primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isAnswered && isCorrect == true
                ? AppColors.gameCorrect.withValues(alpha: 0.12)
                : primaryColor.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Role Clue Badge
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: primaryColor,
                        size: 14.r,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          targetRole != null
                              ? 'TARGET: ${targetRole!.toUpperCase()}'
                              : 'SYNTACTIC SLOT',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                            letterSpacing: 0.8,
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
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.5,
              ),
              children: [
                TextSpan(text: beforeText),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? (isCorrect == true
                                ? AppColors.gameCorrect.withValues(alpha: 0.15)
                                : AppColors.gameIncorrect.withValues(
                                    alpha: 0.15,
                                  ))
                          : primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isAnswered
                            ? (isCorrect == true
                                  ? AppColors.gameCorrect
                                  : AppColors.gameIncorrect)
                            : primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      isAnswered && formedWord != null
                          ? formedWord!.toUpperCase()
                          : (targetRole != null ? '[$targetRole]' : '_______'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isAnswered
                            ? (isCorrect == true
                                  ? AppColors.gameCorrect
                                  : AppColors.gameIncorrect)
                            : primaryColor,
                        letterSpacing: 0.5,
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

          if (isAnswered && isCorrect == false && bounceFeedback != null) ...[
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
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
          ],
        ],
      ),
    );

    return ShakeableWrapper(shakeCount: shakeCount, child: cardContent);
  }
}
