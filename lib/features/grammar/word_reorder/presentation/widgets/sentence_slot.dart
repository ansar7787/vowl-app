import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import './word_builder_tile.dart';

class SentenceSlot extends StatelessWidget {
  final String? word;
  final bool isHovered;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;
  final bool isMidnight;

  const SentenceSlot({
    super.key,
    this.word,
    required this.isHovered,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: word != null ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        constraints: BoxConstraints(minWidth: 60.w, minHeight: 48.h),
        decoration: BoxDecoration(
          color: isHovered
              ? primaryColor.withValues(alpha: 0.1)
              : (isMidnight
                    ? Colors.black.withValues(alpha: 0.2)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.02))),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isHovered
                ? primaryColor
                : (word != null
                      ? primaryColor.withValues(alpha: 0.3)
                      : primaryColor.withValues(alpha: 0.1)),
            width: 1.5,
            style: word != null ? BorderStyle.solid : BorderStyle.none,
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: word != null
            ? WordBuilderTile(
                word: word!,
                onTap: onTap,
                primaryColor: primaryColor,
                isDark: isDark,
                isMidnight: isMidnight,
                isDragged: false,
              ).animate().scale(duration: 200.ms)
            : Center(
                child:
                    Container(
                          width: 20.w,
                          height: 2.h,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .shimmer(
                          duration: 2.seconds,
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
              ),
      ),
    );
  }
}
