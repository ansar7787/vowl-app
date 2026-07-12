import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class CompleteSentenceExplanationCard extends StatelessWidget {
  final GameQuest quest;
  final bool isCorrect;
  final Color primaryColor;
  final bool isDark;

  const CompleteSentenceExplanationCard({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: dark-mode-aware color — was always greenAccent/redAccent.
    final displayColor = isCorrect
        ? (isDark ? Colors.greenAccent : const Color(0xFF16A34A))
        : (isDark ? Colors.redAccent : const Color(0xFFDC2626));

    // FIX: local variable avoids repeated null check and force-unwrap.
    final explanation = quest.explanation;

    final resultLabel = isCorrect
        ? context.tr('games.correct')
        : context.tr('games.incorrect');
    final semanticLabel = explanation != null
        ? '$resultLabel ${context.tr('games.explanation')}: $explanation'
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
            // Decorative icon — text label carries the meaning for a11y.
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
                  ? context.tr('games.correct_caps')
                  : context.tr('games.incorrect_caps'),
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

    // FIX: shimmer only on correct — shimmer signals reward/celebration.
    // Incorrect answers now shake to reinforce the error clearly.
    return isCorrect
        ? card.animate().shimmer(duration: 2.seconds)
        : card.animate().shake(duration: 400.ms);
  }
}
