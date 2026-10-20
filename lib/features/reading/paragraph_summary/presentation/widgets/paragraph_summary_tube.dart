import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParagraphSummaryTube extends StatelessWidget {
  final String passage;
  final List<String> keywords;
  final Color color;
  final bool isDark;
  final double pinchWidth;
  final bool isDistilled;
  final bool isPinching;

  const ParagraphSummaryTube({
    super.key,
    required this.passage,
    required this.keywords,
    required this.color,
    required this.isDark,
    required this.pinchWidth,
    required this.isDistilled,
    this.isPinching = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxCardWidth = constraints.maxWidth;
        final double currentWidth =
            (maxCardWidth * pinchWidth).clamp(160.w, maxCardWidth);

        return AnimatedContainer(
          duration:
              isPinching ? Duration.zero : const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: currentWidth,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: isDark ? color.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.45 : 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !isDistilled
                  ? Column(
                      key: const ValueKey("passage"),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 15.r,
                              color: color.withValues(alpha: 0.9),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Passage',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: color.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          passage,
                          textAlign: TextAlign.start,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.55,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.92)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey("keywords"),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 15.r,
                              color: color.withValues(alpha: 0.9),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Key Ideas',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                                color: color.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ...keywords.asMap().entries.map((entry) {
                          final index = entry.key;
                          final k = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == keywords.length - 1 ? 0 : 8.h,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(
                                    alpha: isDark ? 0.12 : 0.07),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22.r,
                                    height: 22.r,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      k,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.92)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 250.ms)
                                .slideY(begin: 0.08, end: 0),
                          );
                        }),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
