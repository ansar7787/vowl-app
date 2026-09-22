import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceOrderReadingStoneSlab extends StatelessWidget {
  final String text;
  final int index;
  final Color color;
  final bool isDark;
  final RegExp? transitionRegex;

  const SentenceOrderReadingStoneSlab({
    required Key key,
    required this.text,
    required this.index,
    required this.color,
    required this.isDark,
    this.transitionRegex,
  }) : super(key: key);

  List<TextSpan> _buildHighlightedSpans() {
    if (transitionRegex == null) {
      return [TextSpan(text: text)];
    }

    final matches = transitionRegex!.allMatches(text);
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
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_handle_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 24.r,
            ),
          ),
        ],
      ),
    );
  }
}
