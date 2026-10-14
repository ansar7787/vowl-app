import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceOrderReadingStoneSlab extends StatelessWidget {
  final String text;
  final int index;
  final Color color;
  final bool isDark;
  final RegExp? transitionRegex;
  final bool isSelected;
  final VoidCallback? onTap;

  const SentenceOrderReadingStoneSlab({
    required Key key,
    required this.text,
    required this.index,
    required this.color,
    required this.isDark,
    this.transitionRegex,
    this.isSelected = false,
    this.onTap,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: isSelected ? 12 : 10,
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
                color: isSelected ? color : color.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: isSelected ? Colors.white : color,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
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
            SizedBox(width: 8.w),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white24 : Colors.black26),
                  size: 24.r,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
