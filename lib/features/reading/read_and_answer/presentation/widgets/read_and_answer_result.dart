import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color34d399 = Color(0xFF34D399);
  static const Color color059669 = Color(0xFF059669);
  static const Color colorf87171 = Color(0xFFF87171);
  static const Color colordc2626 = Color(0xFFDC2626);
  static const Color color064e3b = Color(0xFF064E3B);
  static const Color colord1fae5 = Color(0xFFD1FAE5);
  static const Color color7f1d1d = Color(0xFF7F1D1D);
  static const Color colorfee2e2 = Color(0xFFFEE2E2);
}

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
        ? (isDark ? _LocalPalette.color34d399 : _LocalPalette.color059669)
        : (isDark ? _LocalPalette.colorf87171 : _LocalPalette.colordc2626);

    final cardBg = isCorrect
        ? (isDark
              ? _LocalPalette.color064e3b.withValues(alpha: 0.2)
              : _LocalPalette.colord1fae5.withValues(alpha: 0.5))
        : (isDark
              ? _LocalPalette.color7f1d1d.withValues(alpha: 0.2)
              : _LocalPalette.colorfee2e2.withValues(alpha: 0.5));

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
                      : context.tr(
                          'games.incorrect_caps',
                          fallback: 'INCORRECT',
                        ),
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
                      : AppColors.slate600,
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
