import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SentenceOrderReadingResult extends StatelessWidget {
  final ReadingQuest quest;
  final bool isCorrect;
  final bool isDark;

  const SentenceOrderReadingResult({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final displayColor = isCorrect ? tokens.gameCorrect : tokens.gameIncorrect;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: displayColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: displayColor,
            size: 36.r,
          ),
          SizedBox(height: 10.h),
          Text(
            isCorrect
                ? context.tr('games.correct', fallback: 'Correct').toUpperCase()
                : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (!isCorrect &&
              quest.shuffledSentences != null &&
              quest.correctOrder != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.white54,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr(
                      'games.correct_order',
                      fallback: 'Correct Order:',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    quest.correctOrder!
                        .where(
                          (index) =>
                              index >= 0 &&
                              index < quest.shuffledSentences!.length,
                        )
                        .map((index) => quest.shuffledSentences![index])
                        .join(' '),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (quest.explanation != null) ...[
            SizedBox(height: 16.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
