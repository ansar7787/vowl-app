import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  const SpeechContextCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final questionText = quest.question;
    final sentenceText = quest.sentence;
    final targetWord = quest.targetWord;

    final isSentencePresent = sentenceText != null && sentenceText.isNotEmpty;
    final isQuestionPresent = questionText != null && questionText.isNotEmpty;

    final mainFontSize = isCompact ? 15.sp : 18.sp;
    final questionFontSize = isCompact ? 13.sp : 15.sp;

    return Semantics(
      label: 'Context: ${sentenceText ?? questionText}',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          key: ValueKey(quest.hashCode),
          padding: EdgeInsets.all(isCompact ? 14.r : 22.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isQuestionPresent)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: isSentencePresent ? 12.h : 0,
                  ),
                  child: Text(
                    questionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: questionFontSize,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (isSentencePresent)
                _buildHighlightedSentence(
                  sentenceText,
                  targetWord,
                  mainFontSize,
                ),
              if (quest.transformations != null &&
                  quest.transformations!.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: quest.transformations!
                      .map(
                        (word) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
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
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
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
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: fontSize,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlighted,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              decorationColor: primaryColor.withValues(alpha: 0.5),
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
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: fontSize,
        color: isDark ? Colors.white : Colors.black87,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
