import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SentenceBuilderExplanationCard extends StatelessWidget {
  final GameQuest quest;
  final bool isCorrect;
  final Color primaryColor;
  final bool isDark;

  const SentenceBuilderExplanationCard({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isCorrect
        ? (isDark ? Colors.greenAccent : const Color(0xFF16A34A))
        : (isDark ? Colors.redAccent : const Color(0xFFDC2626));

    // FIX: local variable so we use the non-null value without repeating
    // the null check or using the force-unwrap `quest.explanation!`.
    final explanation = quest.explanation;

    final resultLabel = isCorrect
        ? context.tr('games.correct', fallback: 'Correct')
        : context.tr('games.incorrect', fallback: 'Incorrect');
    final semanticLabel = explanation != null
        ? '$resultLabel ${context.tr('games.explanation', fallback: 'Explanation')}: $explanation'
        : resultLabel;

    Widget card = Semantics(
      label: semanticLabel,
      child: Container(
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
            // ACCESSIBILITY: icon is decorative — the text below carries meaning.
            ExcludeSemantics(
              child: Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: displayColor,
                size: 36.r,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              isCorrect
                  ? context.tr('games.correct_caps', fallback: 'CORRECT')
                  : context.tr('games.incorrect_caps', fallback: 'INCORRECT'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            if (explanation != null) ...[
              SizedBox(height: 10.h),
              Text(
                // FIX: use local non-null variable instead of force-unwrap.
                explanation,
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
      ),
    );

    // FIX: shimmer only on correct answers.
    // Shimmer signals celebration/reward — applying it to wrong answers
    // creates confusing feedback (rewarding a mistake visually).
    if (isCorrect) {
      return card.animate().shimmer(duration: 2.seconds);
    }
    return card.animate().shake(duration: 400.ms);
  }
}
