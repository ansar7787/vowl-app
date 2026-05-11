import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SentenceHighlighter extends StatelessWidget {
  final String sentence;
  final String targetWord;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;

  const SentenceHighlighter({
    super.key,
    required this.sentence,
    required this.targetWord,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Clean up target word by removing any punctuation for matching
    final cleanTarget = targetWord.replaceAll(RegExp(r'[^\w\s]'), '').trim();

    // 2. We need a way to find where the target word is in the sentence safely.
    // The sentence might contain "quickly." and targetWord is "quickly"

    // Instead of raw string split, let's use a RichText with TextSpans.
    // This regex matches the cleanTarget as a whole word, even if it has punctuation next to it.
    final regex = RegExp(
      r'\b' + RegExp.escape(cleanTarget) + r'\b',
      caseSensitive: false,
    );
    final matches = regex.allMatches(sentence);

    if (matches.isEmpty) {
      // Fallback if not found perfectly
      return Text(
        sentence,
        style: _getBaseStyle(),
        textAlign: TextAlign.center,
      );
    }

    List<InlineSpan> spans = [];
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        // Text before the match
        spans.add(
          TextSpan(
            text: sentence.substring(currentIndex, match.start),
            style: _getBaseStyle(),
          ),
        );
      }

      // The match itself
      final matchedText = sentence.substring(match.start, match.end);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child:
              Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      matchedText,
                      style: GoogleFonts.outfit(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 1.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < sentence.length) {
      // Remaining text
      spans.add(
        TextSpan(
          text: sentence.substring(currentIndex),
          style: _getBaseStyle(),
        ),
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  TextStyle _getBaseStyle() {
    return GoogleFonts.outfit(
      fontSize: 22.sp,
      fontWeight: FontWeight.w600,
      color: isMidnight
          ? Colors.white70
          : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
      height: 1.6,
    );
  }
}
