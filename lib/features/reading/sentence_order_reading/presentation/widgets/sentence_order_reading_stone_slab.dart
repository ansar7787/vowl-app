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
            fontWeight: FontWeight.w700,
            backgroundColor: color.withValues(alpha: isDark ? 0.22 : 0.12),
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
    final unselectedBorderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    final unselectedBgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.20 : 0.08)
              : unselectedBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? color : unselectedBorderColor,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: isDark ? 0.3 : 0.2)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? color
                    : color.withValues(alpha: isDark ? 0.20 : 0.12),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: isSelected ? Colors.white : color,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: RichText(
                softWrap: true,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.95)
                        : const Color(0xFF0F172A),
                  ),
                  children: _buildHighlightedSpans(),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white54 : Colors.black45),
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
