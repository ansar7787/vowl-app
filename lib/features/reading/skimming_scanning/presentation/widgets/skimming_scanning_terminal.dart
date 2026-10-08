import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

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
    final List<String> chunks = _getChunks(text, correct);

    return Container(
      constraints: BoxConstraints(minHeight: 150.h, maxHeight: 260.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Scrolling Content
          Positioned.fill(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 12.h,
                children: chunks.map((word) {
                  final clean = _cleanWord(word);
                  final isCorrectTarget =
                      clean.toLowerCase() == _cleanWord(correct).toLowerCase();
                  final bool isTapped = isAnswered && isCorrectTarget;

                  return GestureDetector(
                    onTap: () => onTapWord(clean, isCorrectTarget),
                    child: AnimatedContainer(
                      duration: 300.milliseconds,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isTapped
                            ? tokens.gameCorrect.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isTapped
                              ? tokens.gameCorrect
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          color: isTapped
                              ? tokens.gameCorrect
                              : tokens.gameCorrect.withValues(alpha: 0.8),
                          fontWeight: isTapped
                              ? FontWeight.bold
                              : FontWeight.normal,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // CRT Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),

          // Scanline
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
        ],
      ),
    );
  }
}
