import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ReadingConclusionResult extends StatelessWidget {
  final ReadingQuest quest;
  final bool isCorrect;
  final bool isDark;

  const ReadingConclusionResult({
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
          if (quest.logicChain != null && quest.logicChain!.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Text(
              'LOGIC CHAIN',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white54 : Colors.black54,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                children: List.generate(quest.logicChain!.length, (index) {
                  final step = quest.logicChain![index];
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: displayColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          step,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (index < quest.logicChain!.length - 1)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            color: displayColor.withValues(alpha: 0.5),
                            size: 20.r,
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
