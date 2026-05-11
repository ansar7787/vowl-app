import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'sentence_display.dart';

class ArticleSentenceCard extends StatelessWidget {
  final int difficulty;
  final String sentenceText;
  final String articleText;
  final bool? lastAnswerCorrect;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;

  const ArticleSentenceCard({
    super.key,
    required this.difficulty,
    required this.sentenceText,
    required this.articleText,
    this.lastAnswerCorrect,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      borderRadius: BorderRadius.circular(32.r),
      borderColor: primaryColor.withValues(alpha: 0.3),
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.02),
      child: SentenceDisplay(
        text: sentenceText,
        correctAnswer: articleText,
        isAnsweredCorrectly: lastAnswerCorrect,
        isDark: isDark,
        primaryColor: primaryColor,
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}
