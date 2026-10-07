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
    return AnimatedContainer(
      duration: isPinching ? Duration.zero : 200.milliseconds,
      width: 320.w * pinchWidth,
      padding: isDistilled 
          ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h)
          : EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r * pinchWidth),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AnimatedSize(
        duration: 300.milliseconds,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: 400.milliseconds,
          child: !isDistilled
            ? Text(
                passage,
                key: const ValueKey("passage"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              )
            : Column(
                key: const ValueKey("keywords"),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: keywords
                    .map(
                      (k) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Text(
                            k,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : color,
                            ),
                          ),
                        ).animate().scale(duration: 300.milliseconds),
                      ),
                    )
                    .toList(),
              ),
        ),
      ),
    );
  }
}
