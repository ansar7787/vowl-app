import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';

/// Displays the sentence or question context for the current quest.
///
/// The entrance animation is keyed on [quest] so it re-triggers whenever
/// the quest changes — without a key the animation only plays once on first
/// build and is skipped for subsequent quests.
class SpeechContextCard extends StatelessWidget {
  final GrammarQuest quest;
  final Color primaryColor;
  final bool isDark;
  final bool isCompact;
  final double? horizontalMargin;

  const SpeechContextCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    this.isCompact = false,
    this.horizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    final questionText = quest.question;
    final sentenceText = quest.sentence;
    final targetWord = quest.targetWord;

    final isSentencePresent = sentenceText != null && sentenceText.isNotEmpty;
    final isQuestionPresent = questionText != null && questionText.isNotEmpty;

    final mainFontSize = isCompact ? 14.sp : 16.sp;
    final questionFontSize = isCompact ? 12.sp : 14.sp;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final cardContent = Container(
      key: ValueKey(quest.hashCode),
      padding: EdgeInsets.all(isCompact ? 12.r : 18.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isCompact ? 16.r : 20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isQuestionPresent)
            Padding(
              padding: EdgeInsets.only(bottom: isSentencePresent ? 10.h : 0),
              child: Text(
                questionText,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: questionFontSize,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF4A5568),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (isSentencePresent)
            _buildHighlightedSentence(sentenceText, targetWord, mainFontSize),
          if (quest.transformations != null &&
              quest.transformations!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: quest.transformations!
                  .map(
                    (word) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isCompact ? 11.sp : 12.sp,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      key: const ValueKey('speech_context_card'),
      label: 'Context: ${sentenceText ?? questionText}',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalMargin ?? 24.w),
        child: reduceMotion
            ? cardContent
            : cardContent
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildHighlightedSentence(
    String sentence,
    String? target,
    double fontSize,
  ) {
    if (target == null || target.isEmpty) {
      return _buildStandardText(sentence, fontSize);
    }

    // Match exact word, case-insensitive, avoiding substring matches inside other words
    final regExp = RegExp(
      r'\b' + RegExp.escape(target) + r'\b',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(sentence);

    int startIndex = -1;
    int endIndex = -1;

    if (match != null) {
      startIndex = match.start;
      endIndex = match.end;
    } else {
      // Fallback to simple substring match if RegExp fails (e.g. due to unusual punctuation in target)
      final lowerSentence = sentence.toLowerCase();
      final lowerTarget = target.toLowerCase();
      startIndex = lowerSentence.indexOf(lowerTarget);
      if (startIndex != -1) {
        endIndex = startIndex + target.length;
      }
    }

    if (startIndex == -1) {
      return _buildStandardText(sentence, fontSize);
    }

    final before = sentence.substring(0, startIndex);
    final highlighted = sentence.substring(startIndex, endIndex);
    final after = sentence.substring(endIndex);

    return RichText(
      textAlign: TextAlign.center,
      softWrap: true,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: fontSize,
          color: isDark ? Colors.white : const Color(0xFF1A202C),
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlighted,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: primaryColor.withValues(alpha: 0.6),
              decorationThickness: 2.0,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildStandardText(String sentence, double fontSize) {
    return Text(
      sentence,
      textAlign: TextAlign.center,
      softWrap: true,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: fontSize,
        color: isDark ? Colors.white : const Color(0xFF1A202C),
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
