import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SentenceOrderReadingStoneSlab extends StatelessWidget {
  final String text;
  final int index;
  final Color color;
  final bool isDark;
  final List<String>? transitionWords;

  const SentenceOrderReadingStoneSlab({
    required Key key,
    required this.text,
    required this.index,
    required this.color,
    required this.isDark,
    this.transitionWords,
  }) : super(key: key);

  List<TextSpan> _buildHighlightedSpans() {
    if (transitionWords == null || transitionWords!.isEmpty) {
      return [TextSpan(text: text)];
    }

    // Sort by length descending to match longer phrases first (e.g., "As a result" before "As")
    final sortedWords = List<String>.from(transitionWords!)
      ..sort((a, b) => b.length.compareTo(a.length));

    final pattern = sortedWords.map((e) => RegExp.escape(e)).join('|');
    final regex = RegExp('($pattern)', caseSensitive: false);

    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return [TextSpan(text: text)];
    }

    int lastEnd = 0;
    final spans = <TextSpan>[];

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            backgroundColor: color.withValues(alpha: 0.2),
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: GlassTile(
        padding: EdgeInsets.all(24.r),
        borderRadius: BorderRadius.circular(15.r),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 2,
        ),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: color,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    height: 1.4,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black87,
                  ),
                  children: _buildHighlightedSpans(),
                ),
              ),
            ),
            Icon(
              Icons.drag_handle_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 24.r,
            ),
          ],
        ),
      ),
    );
  }
}
