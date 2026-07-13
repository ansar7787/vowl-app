import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class ReadAndAnswerResult extends StatelessWidget {
  final ReadingQuest quest;
  final bool isCorrect;
  final bool isDark;

  const ReadAndAnswerResult({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final displayColor = isCorrect
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626));

    final cardBg = isCorrect
        ? (isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.2)
              : const Color(0xFFD1FAE5).withValues(alpha: 0.5))
        : (isDark
              ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
              : const Color(0xFFFEE2E2).withValues(alpha: 0.5));

    final explanation = quest.explanation;

    // Full semantic label for screen readers — they hear the complete result
    // including the explanation in one announcement.
    final semanticLabel = [
      isCorrect ? 'Correct insight!' : 'Incorrect.',
      if (explanation != null && explanation.isNotEmpty) explanation,
    ].join(' ');

    Widget card = Semantics(
      // liveRegion: the card slides in AFTER the player answers. Without this,
      // screen reader users would have to manually navigate to discover the result.
      liveRegion: true,
      label: semanticLabel,
      // excludeSemantics: prevents child Text / Icon widgets from creating
      // redundant announcements — the wrapper label covers everything.
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: displayColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decorative — semantic label above covers correct/incorrect.
                ExcludeSemantics(
                  child: Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: displayColor,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  isCorrect
                      ? 'CORRECT INSIGHT!'
                      : context.tr('games.incorrect_caps', fallback: 'INCORRECT', fallback: 'INCORRECT'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: displayColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            if (explanation != null && explanation.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Divider(color: displayColor.withValues(alpha: 0.1), height: 1),
              SizedBox(height: 12.h),
              Text(
                // Guarded above — explanation is non-null and non-empty here.
                explanation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  height: 1.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (reduceMotion) return card;

    return card.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
