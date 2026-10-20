import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkimmingScanningTerminal extends StatelessWidget {
  final String text;
  final String correct;
  final Color color;
  final ScrollController scrollController;
  final bool isAnswered;
  final Function(String, bool) onTapWord;

  const SkimmingScanningTerminal({
    super.key,
    required this.text,
    required this.correct,
    required this.color,
    required this.scrollController,
    required this.isAnswered,
    required this.onTapWord,
  });

  String _cleanWord(String word) {
    return word
        .replaceAll(RegExp(r'''[.,\/#!$%\^&\*;:{}=\-_`~()\[\]"'?]'''), '')
        .trim();
  }

  List<String> _getChunks(String text, String correct) {
    if (correct.trim().isEmpty) return text.split(RegExp(r'\s+'));

    List<String> rawWords = text.split(RegExp(r'\s+'));
    List<String> correctParts = correct.split(RegExp(r'\s+'));

    if (correctParts.length <= 1) return rawWords;

    List<String> merged = [];
    for (int i = 0; i < rawWords.length; i++) {
      bool match = true;
      if (i + correctParts.length <= rawWords.length) {
        for (int j = 0; j < correctParts.length; j++) {
          if (_cleanWord(rawWords[i + j]).toLowerCase() !=
              _cleanWord(correctParts[j]).toLowerCase()) {
            match = false;
            break;
          }
        }
      } else {
        match = false;
      }

      if (match) {
        String mergedWord = rawWords
            .sublist(i, i + correctParts.length)
            .join(' ');
        merged.add(mergedWord);
        i += correctParts.length - 1;
      } else {
        merged.add(rawWords[i]);
      }
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> chunks = _getChunks(text, correct);

    final cardBg = isDark ? const Color(0xFF141824) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.18);
    final cardShadow = isDark
        ? Colors.black.withValues(alpha: 0.35)
        : color.withValues(alpha: 0.06);

    final Color wordTextNormal = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF1E293B);
    final Color wordBgNormal = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : color.withValues(alpha: 0.04);
    final Color wordBorderNormal = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : color.withValues(alpha: 0.1);

    return Container(
      constraints: BoxConstraints(minHeight: 140.h, maxHeight: 260.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          child: Wrap(
            spacing: 6.w,
            runSpacing: 8.h,
            children: chunks.map((word) {
              final clean = _cleanWord(word);
              final isCorrectTarget =
                  clean.toLowerCase() == _cleanWord(correct).toLowerCase();
              final bool isTapped = isAnswered && isCorrectTarget;

              return GestureDetector(
                onTap: isAnswered
                    ? null
                    : () => onTapWord(clean, isCorrectTarget),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 9.w,
                    vertical: 5.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isTapped
                        ? tokens.gameCorrect.withValues(
                            alpha: isDark ? 0.22 : 0.15,
                          )
                        : wordBgNormal,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isTapped
                          ? tokens.gameCorrect
                          : wordBorderNormal,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    word,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      color: isTapped ? tokens.gameCorrect : wordTextNormal,
                      fontWeight: isTapped ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.3,
                      height: 1.35,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

