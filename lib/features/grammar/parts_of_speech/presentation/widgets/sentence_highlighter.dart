import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Renders [sentence] as rich text with [targetWord] highlighted inside a
/// styled pill that pulses with a scale animation.
///
/// **Regex note:** The word-boundary marker `\b` works only for ASCII
/// characters. Sentences containing diacritics or CJK text will not match
/// correctly. For a multilingual app, replace with a Unicode-aware split.
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
    // Strip punctuation from target for reliable boundary matching.
    final cleanTarget = targetWord.replaceAll(RegExp(r'[^\w\s]'), '').trim();

    final regex = RegExp(
      r'\b' + RegExp.escape(cleanTarget) + r'\b',
      caseSensitive: false,
    );
    final matches = regex.allMatches(sentence);

    // Accessibility: expose the full sentence to screen readers regardless
    // of how it is visually fragmented by spans.
    return Semantics(
      label: sentence,
      child: matches.isEmpty
          ? Text(sentence, style: _baseStyle(), textAlign: TextAlign.center)
          : RichText(
              textAlign: TextAlign.center,
              // FIX: respect system text-scale factor (was missing entirely).
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(children: _buildSpans(sentence, matches)),
            ),
    );
  }

  List<InlineSpan> _buildSpans(String text, Iterable<RegExpMatch> matches) {
    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: _baseStyle(),
          ),
        );
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _HighlightPill(
            text: text.substring(match.start, match.end),
            primaryColor: primaryColor,
          ),
        ),
      );

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: _baseStyle()));
    }
    return spans;
  }

  TextStyle _baseStyle() => TextStyle(
    fontFamily: 'Outfit',
    fontSize: 22.sp,
    fontWeight: FontWeight.w600,
    color: isMidnight
        ? Colors.white70
        : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
    height: 1.6,
  );
}

// ---------------------------------------------------------------------------
// Private pill widget — extracted so the animation controller is scoped to
// only this small widget, not the entire RichText rebuild.
// ---------------------------------------------------------------------------

class _HighlightPill extends StatelessWidget {
  final String text;
  final Color primaryColor;

  const _HighlightPill({required this.text, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
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
        );
  }
}
