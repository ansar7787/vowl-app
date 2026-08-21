import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ParagraphSummaryResult extends StatelessWidget {
  final ReadingQuest quest;
  final bool isCorrect;
  final bool isDark;

  const ParagraphSummaryResult({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isCorrect ? Colors.greenAccent : Colors.redAccent;

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
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
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
          if (quest.keyPoints != null && quest.keyPoints!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'KEY POINTS CHECKLIST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white54 : Colors.black54,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...quest.keyPoints!.map((point) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isCorrect ? Colors.greenAccent : (isDark ? Colors.white30 : Colors.black26),
                          size: 18.r,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              color: isCorrect 
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
