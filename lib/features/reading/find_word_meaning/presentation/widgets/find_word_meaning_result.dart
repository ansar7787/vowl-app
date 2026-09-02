import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class FindWordMeaningResult extends StatelessWidget {
  final ReadingQuest quest;
  final bool isCorrect;
  final bool isDark;

  const FindWordMeaningResult({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isCorrect ? Colors.greenAccent : Colors.redAccent;

    Widget card = Semantics(
      liveRegion: true,
      label: isCorrect
          ? 'Correct! ${quest.explanation ?? ''}'
          : 'Incorrect. ${quest.explanation ?? ''}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark
              ? displayColor.withValues(alpha: 0.1)
              : displayColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: displayColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: displayColor,
                  size: 32.r,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              isCorrect
                  ? context
                        .tr('games.correct', fallback: 'Correct')
                        .toUpperCase()
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  height: 1.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF475569),
                ),
              ),
            ],
            if (quest.wordInContext != null) ...[
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Example Usage',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.black45,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '"${quest.wordInContext}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return card;
    return card.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
